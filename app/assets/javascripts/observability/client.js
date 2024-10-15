import { isValidDate } from '~/lib/utils/datetime_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import axios from '~/lib/utils/axios_utils';
import { logError } from '~/lib/logger';
import { DEFAULT_SORTING_OPTION, SORTING_OPTIONS, CUSTOM_DATE_RANGE_OPTION } from './constants';

function reportErrorAndThrow(e) {
  logError(e);
  Sentry.captureException(e);
  throw e;
}

/** ****
 *
 * Provisioning API
 *
 * ***** */

// Provisioning API spec: https://gitlab.com/gitlab-org/opstrace/opstrace/-/blob/main/provisioning-api/pkg/provisioningapi/routes.go#L59
async function enableObservability(provisioningUrl) {
  try {
    // Note: axios.put(url, undefined, {withCredentials: true}) does not send cookies properly, so need to use the API below for the correct behaviour
    return await axios(provisioningUrl, {
      method: 'put',
      withCredentials: true,
    });
  } catch (e) {
    return reportErrorAndThrow(e);
  }
}

// Provisioning API spec: https://gitlab.com/gitlab-org/opstrace/opstrace/-/blob/main/provisioning-api/pkg/provisioningapi/routes.go#L37
async function isObservabilityEnabled(provisioningUrl) {
  try {
    const { data } = await axios.get(provisioningUrl, { withCredentials: true });
    if (data && data.status) {
      // we currently ignore the 'status' payload and just check if the request was successful
      // We might improve this as part of https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2315
      return true;
    }
  } catch (e) {
    if (e.response.status === 404) {
      return false;
    }
    return reportErrorAndThrow(e);
  }
  return reportErrorAndThrow(new Error('Failed to check provisioning')); // eslint-disable-line @gitlab/require-i18n-strings
}

/** ****
 *
 * Common utils
 *
 * ***** */

const FILTER_OPERATORS_PREFIX = {
  '!=': 'not',
  '>': 'gt',
  '<': 'lt',
  '!~': 'not_like',
  '=~': 'like',
};

const SEARCH_FILTER_NAME = 'search';

/**
 * Return the query parameter name, given an operator and param key
 *
 * e.g
 *    if paramKey is 'foo' and operator is "=", param name is 'foo'
 *    if paramKey is 'foo' and operator is "!=", param name is 'not[foo]'
 *
 * @param {String} paramKey - The parameter name
 * @param {String} operator - The operator
 * @returns String | undefined - Query param name
 */
function getFilterParamName(filterName, operator, filterToQueryMapping) {
  const paramKey = filterToQueryMapping[filterName];
  if (!paramKey) return undefined;

  if (operator === '=' || filterName === SEARCH_FILTER_NAME) {
    return paramKey;
  }

  const prefix = FILTER_OPERATORS_PREFIX[operator];
  if (prefix) {
    return `${prefix}[${paramKey}]`;
  }

  return undefined;
}

/**
 * Process `filterValue` and append the proper query params to the  `searchParams` arg, using `nameParam` and `valueParam`
 *
 * It mutates `searchParams`
 *
 * @param {String} filterValue The filter value, in the format `attribute_name=attribute_value`
 * @param {String} filterOperator The filter operator
 * @param {URLSearchParams} searchParams The URLSearchParams object where to append the proper query params
 * @param {String} nameParam The query param name for the attribute name
 * @param {String} nameParam The query param name for the attribute value
 *
 * e.g.
 *
 *    handleAttributeFilter('foo=bar', '=', searchParams, 'attr_name', 'attr_value')
 *
 *        it adds { attr_name: 'foo', attr_value: 'bar'} to `searchParams`
 *
 */
function handleAttributeFilter(filterValue, filterOperator, searchParams, nameParam, valueParam) {
  const [attrName, attrValue] = filterValue.split('=');
  if (attrName && attrValue) {
    if (filterOperator === '=') {
      searchParams.append(nameParam, attrName);
      searchParams.append(valueParam, attrValue);
    }
  }
}

function addDateRangeFilterToQueryParams(dateRangeFilter, params) {
  if (!dateRangeFilter || !params) return;

  const { value, endDate, startDate, timestamp } = dateRangeFilter;
  if (timestamp) {
    params.append('start_time', timestamp);
    params.append('end_time', timestamp);
  } else if (value === CUSTOM_DATE_RANGE_OPTION) {
    if (isValidDate(startDate) && isValidDate(endDate)) {
      params.append('start_time', startDate.toISOString());
      params.append('end_time', endDate.toISOString());
    }
  } else if (typeof value === 'string') {
    params.append('period', value);
  }
}

/** ****
 *
 * Tracing API
 *
 * ***** */

async function fetchTrace(tracingUrl, traceId) {
  try {
    if (!traceId) {
      throw new Error('traceId is required.');
    }

    const { data } = await axios.get(`${tracingUrl}/${traceId}`, {
      withCredentials: true,
    });

    return data;
  } catch (e) {
    return reportErrorAndThrow(e);
  }
}

/**
 * Filters (and operators) allowed by tracing query API
 */
const SUPPORTED_TRACING_FILTERS = {
  durationMs: ['>', '<'],
  operation: ['=', '!='],
  service: ['=', '!='],
  period: ['='],
  traceId: ['=', '!='],
  attribute: ['='],
  status: ['=', '!='],
  // 'search' temporarily ignored https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2309
};

/**
 * Mapping of filter name to tracing query param
 */
const TRACING_FILTER_TO_QUERY_PARAM = {
  durationMs: 'duration_nano',
  operation: 'operation',
  service: 'service_name',
  traceId: 'trace_id',
  status: 'status',
  // `attribute` is handled separately, see `handleAttributeFilter` method
  // `period` is handled separately, see `handleTracingPeriodFilter` method
};

function handleTracingPeriodFilter(rawValue, filterName, filterParams) {
  if (rawValue.trim().indexOf(' ') < 0) {
    filterParams.append(filterName, rawValue.trim());
    return;
  }

  const dateParts = rawValue.split(' - ');
  if (dateParts.length === 2) {
    const [start, end] = dateParts;
    const startDate = new Date(start);
    const endDate = new Date(end);
    if (isValidDate(startDate) && isValidDate(endDate)) {
      filterParams.append('start_time', startDate.toISOString());
      filterParams.append('end_time', endDate.toISOString());
    }
  }
}

/**
 * Builds URLSearchParams from a filter object of type { [filterName]: undefined | null | Array<{operator: String, value: any} }
 *  e.g:
 *
 *  filterObj =  {
 *      durationMs: [{operator: '>', value: '100'}, {operator: '<', value: '1000' }],
 *      operation: [{operator: '=', value: 'someOp' }],
 *      service: [{operator: '!=', value: 'foo' }]
 *    }
 *
 * It handles converting the filter to the proper supported query params
 *
 * @param {Object} filterObj : An Object representing filters
 * @returns URLSearchParams
 */
function tracingFilterObjToQueryParams(filterObj) {
  const filterParams = new URLSearchParams();

  Object.keys(SUPPORTED_TRACING_FILTERS).forEach((filterName) => {
    const filterValues = Array.isArray(filterObj[filterName]) ? filterObj[filterName] : [];
    const validFilters = filterValues.filter((f) =>
      SUPPORTED_TRACING_FILTERS[filterName].includes(f.operator),
    );

    validFilters.forEach(({ operator, value: rawValue }) => {
      if (filterName === 'attribute') {
        handleAttributeFilter(rawValue, operator, filterParams, 'attr_name', 'attr_value');
      } else if (filterName === 'period') {
        handleTracingPeriodFilter(rawValue, filterName, filterParams);
      } else {
        const paramName = getFilterParamName(filterName, operator, TRACING_FILTER_TO_QUERY_PARAM);
        let value = rawValue;
        if (filterName === 'durationMs') {
          // converting durationMs to duration_nano
          value *= 1000000;
        }
        if (paramName && value) {
          filterParams.append(paramName, value);
        }
      }
    });
  });
  return filterParams;
}

/**
 * Fetches traces with given tracing API URL and filters
 *
 * @param {String} tracingUrl : The API base URL
 * @param {Object} filters : A filter object of type: { [filterName]: undefined | null | Array<{operator: String, value: String} }
 *  e.g:
 *
 *    {
 *      durationMs: [ {operator: '>', value: '100'}, {operator: '<', value: '1000'}],
 *      operation: [ {operator: '=', value: 'someOp}],
 *      service: [ {operator: '!=', value: 'foo}]
 *    }
 *
 * @returns Array<Trace> : A list of traces
 */
async function fetchTraces(
  tracingUrl,
  { filters = {}, pageToken, pageSize, sortBy, abortController } = {},
) {
  const params = tracingFilterObjToQueryParams(filters);
  if (pageToken) {
    params.append('page_token', pageToken);
  }
  if (pageSize) {
    params.append('page_size', pageSize);
  }
  const sortOrder = Object.values(SORTING_OPTIONS).includes(sortBy)
    ? sortBy
    : DEFAULT_SORTING_OPTION;
  params.append('sort', sortOrder);

  try {
    const { data } = await axios.get(tracingUrl, {
      withCredentials: true,
      params,
      signal: abortController?.signal,
    });
    if (!Array.isArray(data.traces)) {
      throw new Error('traces are missing/invalid in the response'); // eslint-disable-line @gitlab/require-i18n-strings
    }
    return data;
  } catch (e) {
    return reportErrorAndThrow(e);
  }
}

async function fetchTracesAnalytics(tracingAnalyticsUrl, { filters = {}, abortController } = {}) {
  const params = tracingFilterObjToQueryParams(filters);

  try {
    const { data } = await axios.get(tracingAnalyticsUrl, {
      withCredentials: true,
      params,
      signal: abortController?.signal,
    });
    return data.results ?? [];
  } catch (e) {
    return reportErrorAndThrow(e);
  }
}

async function fetchServices(servicesUrl) {
  try {
    const { data } = await axios.get(servicesUrl, {
      withCredentials: true,
    });

    if (!Array.isArray(data.services)) {
      throw new Error('failed to fetch services. invalid response'); // eslint-disable-line @gitlab/require-i18n-strings
    }

    return data.services;
  } catch (e) {
    return reportErrorAndThrow(e);
  }
}

async function fetchOperations(operationsUrl, serviceName) {
  try {
    if (!serviceName) {
      throw new Error('fetchOperations() - serviceName is required.');
    }
    if (!operationsUrl.includes('$SERVICE_NAME$')) {
      throw new Error('fetchOperations() - operationsUrl must contain $SERVICE_NAME$');
    }
    const url = operationsUrl.replace('$SERVICE_NAME$', serviceName);
    const { data } = await axios.get(url, {
      withCredentials: true,
    });

    if (!Array.isArray(data.operations)) {
      throw new Error('failed to fetch operations. invalid response'); // eslint-disable-line @gitlab/require-i18n-strings
    }

    return data.operations;
  } catch (e) {
    return reportErrorAndThrow(e);
  }
}

function handleMetricsAttributeFilters(attributeFilters, params) {
  if (Array.isArray(attributeFilters)) {
    attributeFilters.forEach(
      ({ operator, value }) => operator === '=' && params.append('attributes', value),
    );
  }
}

/** ****
 *
 * Metrics API
 *
 * ***** */

async function fetchMetrics(metricsUrl, { filters = {}, limit } = {}) {
  try {
    const params = new URLSearchParams();

    if (Array.isArray(filters.search)) {
      const search = filters.search
        .map((f) => f.value)
        .join(' ')
        .trim();

      if (search) {
        params.append('search', search);
        if (limit) {
          params.append('limit', limit);
        }
      }
    }

    if (filters.attribute) {
      handleMetricsAttributeFilters(filters.attribute, params);
    }

    const { data } = await axios.get(metricsUrl, {
      withCredentials: true,
      params,
    });
    if (!Array.isArray(data.metrics)) {
      throw new Error('metrics are missing/invalid in the response'); // eslint-disable-line @gitlab/require-i18n-strings
    }
    return data;
  } catch (e) {
    return reportErrorAndThrow(e);
  }
}

const SUPPORTED_METRICS_DIMENSIONS_OPERATORS = {
  '!=': 'neq',
  '=': 'eq',
  '=~': 're',
  '!~': 'nre',
};

function addMetricsAttributeFilterToQueryParams(dimensionFilter, params) {
  if (!dimensionFilter || !params) return;

  Object.entries(dimensionFilter).forEach(([filterName, values]) => {
    const filterValues = Array.isArray(values) ? values : [];
    const validFilters = filterValues.filter((f) =>
      Object.keys(SUPPORTED_METRICS_DIMENSIONS_OPERATORS).includes(f.operator),
    );
    validFilters.forEach(({ operator, value }) => {
      const operatorName = SUPPORTED_METRICS_DIMENSIONS_OPERATORS[operator];
      params.append('attrs', `${filterName},${operatorName},${value}`);
    });
  });
}

function addMetricsGroupByFilterToQueryParams(groupByFilter, params) {
  if (!groupByFilter || !params) return;

  const { func, attributes } = groupByFilter;
  if (func) {
    params.append('groupby_fn', func);
  }
  if (Array.isArray(attributes) && attributes.length > 0) {
    params.append('groupby_attrs', attributes.join(','));
  }
}

async function fetchMetric(searchUrl, name, type, options = {}) {
  try {
    if (!name) {
      throw new Error('fetchMetric() - metric name is required.');
    }
    if (!type) {
      throw new Error('fetchMetric() - metric type is required.');
    }

    const params = new URLSearchParams({
      mname: name,
      mtype: type,
    });

    if (options.visual) {
      params.append('mvisual', options.visual);
    }

    const { attributes, dateRange, groupBy } = options.filters ?? {};

    if (attributes) {
      addMetricsAttributeFilterToQueryParams(attributes, params);
    }

    if (dateRange) {
      addDateRangeFilterToQueryParams(dateRange, params);
    }

    if (groupBy) {
      addMetricsGroupByFilterToQueryParams(groupBy, params);
    }

    const { data } = await axios.get(searchUrl, {
      params,
      signal: options.abortController?.signal,
      withCredentials: true,
    });

    if (!Array.isArray(data.results)) {
      throw new Error('metrics are missing/invalid in the response'); // eslint-disable-line @gitlab/require-i18n-strings
    }
    return data.results;
  } catch (e) {
    return reportErrorAndThrow(e);
  }
}

async function fetchMetricSearchMetadata(searchMetadataUrl, name, type) {
  try {
    if (!name) {
      throw new Error('fetchMetric() - metric name is required.');
    }
    if (!type) {
      throw new Error('fetchMetric() - metric type is required.');
    }

    const params = new URLSearchParams({
      mname: name,
      mtype: type,
    });
    const { data } = await axios.get(searchMetadataUrl, {
      params,
      withCredentials: true,
    });
    return data;
  } catch (e) {
    return reportErrorAndThrow(e);
  }
}

/** ****
 *
 * Logs API
 *
 * ***** */

/**
 * Filters (and operators) allowed by logs query API
 */
const SUPPORTED_LOGS_FILTERS = {
  service: ['=', '!='],
  severityName: ['=', '!='],
  severityNumber: ['=', '!='],
  traceId: ['='],
  spanId: ['='],
  fingerprint: ['='],
  traceFlags: ['=', '!='],
  attribute: ['='],
  resourceAttribute: ['='],
  search: [], // 'search' filter does not have any operator
};

/**
 * Mapping of filter name to query param
 */
const LOGS_FILTER_TO_QUERY_PARAM = {
  service: 'service_name',
  severityName: 'severity_name',
  severityNumber: 'severity_number',
  traceId: 'trace_id',
  spanId: 'span_id',
  fingerprint: 'fingerprint',
  traceFlags: 'trace_flags',
  search: 'body',
  // `attribute` and `resource_attribute` are handled separately
};

/**
 * Builds URLSearchParams from a filter object of type { [filterName]: undefined | null | Array<{operator: String, value: any} }
 *  e.g:
 *
 *  filterObj =  {
 *      severityName: [{operator: '=', value: 'info' }],
 *      service: [{operator: '!=', value: 'foo' }]
 *    }
 *
 * It handles converting the filter to the proper supported query params
 *
 * @param {Object} filterObj : An Object representing handleAttributeFilter
 * @returns URLSearchParams
 */
function addLogsAttributesFiltersToQueryParams(filterObj, filterParams) {
  Object.keys(SUPPORTED_LOGS_FILTERS).forEach((filterName) => {
    const filterValues = Array.isArray(filterObj[filterName])
      ? filterObj[filterName].filter(({ value }) => Boolean(value)) // ignore empty strings
      : [];
    const validFilters = filterValues.filter(
      (f) =>
        (filterName === SEARCH_FILTER_NAME && SUPPORTED_LOGS_FILTERS[filterName]) ||
        SUPPORTED_LOGS_FILTERS[filterName].includes(f.operator),
    );
    validFilters.forEach(({ operator, value: rawValue }) => {
      if (filterName === 'attribute') {
        handleAttributeFilter(rawValue, operator, filterParams, 'log_attr_name', 'log_attr_value');
      } else if (filterName === 'resourceAttribute') {
        handleAttributeFilter(rawValue, operator, filterParams, 'res_attr_name', 'res_attr_value');
      } else {
        const paramName = getFilterParamName(filterName, operator, LOGS_FILTER_TO_QUERY_PARAM);
        const value = rawValue;
        if (paramName && value) {
          filterParams.append(paramName, value);
        }
      }
    });
  });
  return filterParams;
}

export async function fetchLogs(logsSearchUrl, { pageToken, pageSize, filters = {} } = {}) {
  try {
    const params = new URLSearchParams();

    const { dateRange, attributes } = filters;
    if (dateRange) {
      addDateRangeFilterToQueryParams(dateRange, params);
    }

    if (attributes) {
      addLogsAttributesFiltersToQueryParams(attributes, params);
    }

    if (pageToken) {
      params.append('page_token', pageToken);
    }
    if (pageSize) {
      params.append('page_size', pageSize);
    }
    const { data } = await axios.get(logsSearchUrl, {
      withCredentials: true,
      params,
    });
    if (!Array.isArray(data.results)) {
      throw new Error('logs are missing/invalid in the response'); // eslint-disable-line @gitlab/require-i18n-strings
    }
    return {
      logs: data.results,
      nextPageToken: data.next_page_token,
    };
  } catch (e) {
    return reportErrorAndThrow(e);
  }
}

export async function fetchLogsSearchMetadata(_logsSearchMetadataUrl, { filters = {} }) {
  try {
    const params = new URLSearchParams();

    const { dateRange, attributes } = filters;
    if (dateRange) {
      addDateRangeFilterToQueryParams(dateRange, params);
    }

    if (attributes) {
      addLogsAttributesFiltersToQueryParams(attributes, params);
    }

    // TODO remove mocks (and add UTs) when API is ready https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2782
    // const { data } = await axios.get(logsSearchMetadataUrl, {
    //   withCredentials: true,
    //   params,
    // });
    // return data;

    return {
      start_ts: 1713513680617331200,
      end_ts: 1714723280617331200,
      summary: {
        service_names: ['adservice', 'cartservice', 'quoteservice', 'recommendationservice'],
        trace_flags: [0, 1],
        severity_names: ['info', 'warn'],
        severity_numbers: [9, 13],
      },
      severity_numbers_counts: [
        {
          time: 1713519360000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1713545280000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1713571200000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1713597120000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1713623040000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1713648960000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1713674880000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1713700800000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1713726720000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1713752640000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1713778560000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1713804480000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1713830400000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1713856320000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1713882240000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1713908160000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1713934080000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1713960000000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1713985920000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1714011840000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1714037760000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1714063680000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1714089600000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1714115520000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1714141440000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1714167360000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1714193280000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1714219200000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1714245120000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1714271040000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1714296960000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1714322880000000000,
          counts: {
            13: 1,
            9: 26202,
          },
        },
        {
          time: 1714348800000000000,
          counts: {
            13: 0,
            9: 53103,
          },
        },
        {
          time: 1714374720000000000,
          counts: {
            13: 0,
            9: 52854,
          },
        },
        {
          time: 1714400640000000000,
          counts: {
            13: 0,
            9: 49598,
          },
        },
        {
          time: 1714426560000000000,
          counts: {
            13: 0,
            9: 45266,
          },
        },
        {
          time: 1714452480000000000,
          counts: {
            13: 0,
            9: 44951,
          },
        },
        {
          time: 1714478400000000000,
          counts: {
            13: 0,
            9: 45096,
          },
        },
        {
          time: 1714504320000000000,
          counts: {
            13: 0,
            9: 45301,
          },
        },
        {
          time: 1714530240000000000,
          counts: {
            13: 0,
            9: 44894,
          },
        },
        {
          time: 1714556160000000000,
          counts: {
            13: 0,
            9: 45444,
          },
        },
        {
          time: 1714582080000000000,
          counts: {
            13: 0,
            9: 45067,
          },
        },
        {
          time: 1714608000000000000,
          counts: {
            13: 0,
            9: 45119,
          },
        },
        {
          time: 1714633920000000000,
          counts: {
            13: 0,
            9: 45817,
          },
        },
        {
          time: 1714659840000000000,
          counts: {
            13: 0,
            9: 44574,
          },
        },
        {
          time: 1714685760000000000,
          counts: {
            13: 0,
            9: 44652,
          },
        },
        {
          time: 1714711680000000000,
          counts: {
            13: 0,
            9: 20470,
          },
        },
      ],
    };
  } catch (e) {
    return reportErrorAndThrow(e);
  }
}

/** ****
 *
 * ObservabilityClient
 *
 * ***** */

export function buildClient(config) {
  if (!config) {
    throw new Error('No options object provided'); // eslint-disable-line @gitlab/require-i18n-strings
  }

  const {
    provisioningUrl,
    tracingUrl,
    tracingAnalyticsUrl,
    servicesUrl,
    operationsUrl,
    metricsUrl,
    metricsSearchUrl,
    metricsSearchMetadataUrl,
    logsSearchUrl,
    logsSearchMetadataUrl,
  } = config;

  if (typeof provisioningUrl !== 'string') {
    throw new Error('provisioningUrl param must be a string');
  }

  if (typeof tracingUrl !== 'string') {
    throw new Error('tracingUrl param must be a string');
  }

  if (typeof tracingAnalyticsUrl !== 'string') {
    throw new Error('tracingAnalyticsUrl param must be a string');
  }

  if (typeof servicesUrl !== 'string') {
    throw new Error('servicesUrl param must be a string');
  }

  if (typeof operationsUrl !== 'string') {
    throw new Error('operationsUrl param must be a string');
  }

  if (typeof metricsUrl !== 'string') {
    throw new Error('metricsUrl param must be a string');
  }

  if (typeof metricsSearchUrl !== 'string') {
    throw new Error('metricsSearchUrl param must be a string');
  }

  if (typeof metricsSearchMetadataUrl !== 'string') {
    throw new Error('metricsSearchMetadataUrl param must be a string');
  }

  if (typeof logsSearchUrl !== 'string') {
    throw new Error('logsSearchUrl param must be a string');
  }

  if (typeof logsSearchMetadataUrl !== 'string') {
    throw new Error('logsSearchMetadataUrl param must be a string');
  }

  return {
    enableObservability: () => enableObservability(provisioningUrl),
    isObservabilityEnabled: () => isObservabilityEnabled(provisioningUrl),
    fetchTraces: (options) => fetchTraces(tracingUrl, options),
    fetchTracesAnalytics: (options) => fetchTracesAnalytics(tracingAnalyticsUrl, options),
    fetchTrace: (traceId) => fetchTrace(tracingUrl, traceId),
    fetchServices: () => fetchServices(servicesUrl),
    fetchOperations: (serviceName) => fetchOperations(operationsUrl, serviceName),
    fetchMetrics: (options) => fetchMetrics(metricsUrl, options),
    fetchMetric: (metricName, metricType, options) =>
      fetchMetric(metricsSearchUrl, metricName, metricType, options),
    fetchMetricSearchMetadata: (metricName, metricType) =>
      fetchMetricSearchMetadata(metricsSearchMetadataUrl, metricName, metricType),
    fetchLogs: (options) => fetchLogs(logsSearchUrl, options),
    fetchLogsSearchMetadata: (options) => fetchLogsSearchMetadata(logsSearchMetadataUrl, options),
  };
}
