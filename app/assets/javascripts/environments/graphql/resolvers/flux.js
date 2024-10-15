import { Configuration, WatchApi, EVENT_DATA, EVENT_TIMEOUT } from '@gitlab/cluster-client';
import axios from '~/lib/utils/axios_utils';
import {
  HELM_RELEASES_RESOURCE_TYPE,
  KUSTOMIZATIONS_RESOURCE_TYPE,
} from '~/environments/constants';
import { updateConnectionStatus } from '~/environments/graphql/resolvers/kubernetes/k8s_connection_status';
import { connectionStatus } from '~/environments/graphql/resolvers/kubernetes/constants';
import fluxKustomizationStatusQuery from '../queries/flux_kustomization_status.query.graphql';
import fluxHelmReleaseStatusQuery from '../queries/flux_helm_release_status.query.graphql';

const helmReleasesApiVersion = 'helm.toolkit.fluxcd.io/v2beta1';
const kustomizationsApiVersion = 'kustomize.toolkit.fluxcd.io/v1';

const helmReleaseField = 'fluxHelmReleaseStatus';
const kustomizationField = 'fluxKustomizationStatus';

const handleClusterError = (err) => {
  const error = err?.response?.data?.message ? new Error(err.response.data.message) : err;
  throw error;
};

const buildFluxResourceUrl = ({ basePath, namespace, apiVersion, resourceType }) => {
  return `${basePath}/apis/${apiVersion}/namespaces/${namespace}/${resourceType}`;
};

export const buildFluxResourceWatchPath = ({ namespace, apiVersion, resourceType }) => {
  return `/apis/${apiVersion}/namespaces/${namespace}/${resourceType}`;
};

const watchFluxResource = ({
  watchPath,
  resourceName,
  namespace,
  query,
  variables,
  resourceType,
  field,
  client,
}) => {
  const config = new Configuration(variables.configuration);
  const watcherApi = new WatchApi(config);
  const fieldSelector = `metadata.name=${decodeURIComponent(resourceName)}`;

  updateConnectionStatus(client, {
    configuration: variables.configuration,
    namespace,
    resourceType,
    status: connectionStatus.connecting,
  });

  watcherApi
    .subscribeToStream(watchPath, { watch: true, fieldSelector })
    .then((watcher) => {
      let result = [];

      watcher.on(EVENT_DATA, (data) => {
        result = data[0]?.status?.conditions;

        client.writeQuery({
          query,
          variables,
          data: { [field]: result },
        });

        updateConnectionStatus(client, {
          configuration: variables.configuration,
          namespace,
          resourceType,
          status: connectionStatus.connected,
        });
      });

      watcher.on(EVENT_TIMEOUT, () => {
        updateConnectionStatus(client, {
          configuration: variables.configuration,
          namespace,
          resourceType,
          status: connectionStatus.disconnected,
        });
      });
    })
    .catch((err) => {
      handleClusterError(err);
    });
};

const getFluxResourceStatus = ({ query, variables, field, resourceType, client }) => {
  const { headers } = variables.configuration;
  const withCredentials = true;
  const url = `${variables.configuration.basePath}/apis/${variables.fluxResourcePath}`;

  return axios
    .get(url, { withCredentials, headers })
    .then((res) => {
      const fluxData = res?.data;
      const resourceName = fluxData?.metadata?.name;
      const namespace = fluxData?.metadata?.namespace;
      const apiVersion = fluxData?.apiVersion;

      if (gon.features?.k8sWatchApi && resourceName) {
        const watchPath = buildFluxResourceWatchPath({ namespace, apiVersion, resourceType });

        watchFluxResource({
          watchPath,
          resourceName,
          namespace,
          query,
          variables,
          resourceType,
          field,
          client,
        });
      }

      return fluxData?.status?.conditions || [];
    })
    .catch((err) => {
      handleClusterError(err);
    });
};

export const watchFluxKustomization = ({ configuration, client, fluxResourcePath }) => {
  const query = fluxKustomizationStatusQuery;
  const variables = { configuration, fluxResourcePath };
  const field = kustomizationField;
  const resourceType = KUSTOMIZATIONS_RESOURCE_TYPE;

  getFluxResourceStatus({ query, variables, field, resourceType, client });
};

export const watchFluxHelmRelease = ({ configuration, client, fluxResourcePath }) => {
  const query = fluxHelmReleaseStatusQuery;
  const variables = { configuration, fluxResourcePath };
  const field = helmReleaseField;
  const resourceType = HELM_RELEASES_RESOURCE_TYPE;

  getFluxResourceStatus({ query, variables, field, resourceType, client });
};

const getFluxResources = (configuration, url) => {
  const { headers } = configuration;
  const withCredentials = true;

  return axios
    .get(url, { withCredentials, headers })
    .then((res) => {
      const items = res?.data?.items || [];
      const result = items.map((item) => {
        return {
          apiVersion: item.apiVersion,
          metadata: {
            name: item.metadata?.name,
            namespace: item.metadata?.namespace,
          },
        };
      });
      return result || [];
    })
    .catch((err) => {
      const error = err?.response?.data?.reason || err;
      throw new Error(error);
    });
};

export default {
  fluxKustomizationStatus(_, { configuration, fluxResourcePath }, { client }) {
    return getFluxResourceStatus({
      query: fluxKustomizationStatusQuery,
      variables: { configuration, fluxResourcePath },
      field: kustomizationField,
      resourceType: KUSTOMIZATIONS_RESOURCE_TYPE,
      client,
    });
  },
  fluxHelmReleaseStatus(_, { configuration, fluxResourcePath }, { client }) {
    return getFluxResourceStatus({
      query: fluxHelmReleaseStatusQuery,
      variables: { configuration, fluxResourcePath },
      field: helmReleaseField,
      resourceType: HELM_RELEASES_RESOURCE_TYPE,
      client,
    });
  },
  fluxKustomizations(_, { configuration, namespace }) {
    const url = buildFluxResourceUrl({
      basePath: configuration.basePath,
      resourceType: KUSTOMIZATIONS_RESOURCE_TYPE,
      apiVersion: kustomizationsApiVersion,
      namespace,
    });
    return getFluxResources(configuration, url);
  },
  fluxHelmReleases(_, { configuration, namespace }) {
    const url = buildFluxResourceUrl({
      basePath: configuration.basePath,
      resourceType: HELM_RELEASES_RESOURCE_TYPE,
      apiVersion: helmReleasesApiVersion,
      namespace,
    });
    return getFluxResources(configuration, url);
  },
};
