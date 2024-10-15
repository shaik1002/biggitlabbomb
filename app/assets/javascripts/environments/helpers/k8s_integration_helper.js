import csrf from '~/lib/utils/csrf';
import {
  CLUSTER_AGENT_ERROR_MESSAGES,
  STATUS_TRUE,
  STATUS_FALSE,
  STATUS_UNKNOWN,
  REASON_PROGRESSING,
} from '../constants';

export function humanizeClusterErrors(reason) {
  const errorReason = String(reason).toLowerCase();
  const errorMessage = CLUSTER_AGENT_ERROR_MESSAGES[errorReason];
  return errorMessage || CLUSTER_AGENT_ERROR_MESSAGES.other;
}

export function createK8sAccessConfiguration({ kasTunnelUrl, gitlabAgentId }) {
  return {
    basePath: kasTunnelUrl,
    headers: {
      'GitLab-Agent-Id': gitlabAgentId,
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ...csrf.headers,
    },
    credentials: 'include',
  };
}

const fluxAnyStalled = (fluxConditions) => {
  return fluxConditions.find((condition) => {
    return condition.status === STATUS_TRUE && condition.type === 'Stalled';
  });
};
const fluxAnyReconcilingWithBadConfig = (fluxConditions) => {
  return fluxConditions.find((condition) => {
    return (
      condition.status === STATUS_UNKNOWN &&
      condition.type === 'Ready' &&
      condition.reason === REASON_PROGRESSING
    );
  });
};
const fluxAnyReconciling = (fluxConditions) => {
  return fluxConditions.find((condition) => {
    return condition.status === STATUS_TRUE && condition.type === 'Reconciling';
  });
};
const fluxAnyReconciled = (fluxConditions) => {
  return fluxConditions.find((condition) => {
    return condition.status === STATUS_TRUE && condition.type === 'Ready';
  });
};
const fluxAnyFailed = (fluxConditions) => {
  return fluxConditions.find((condition) => {
    return condition.status === STATUS_FALSE && condition.type === 'Ready';
  });
};

export const fluxSyncStatus = (fluxConditions) => {
  if (fluxAnyFailed(fluxConditions)) {
    return { status: 'failed', message: fluxAnyFailed(fluxConditions).message };
  }
  if (fluxAnyStalled(fluxConditions)) {
    return { status: 'stalled', message: fluxAnyStalled(fluxConditions).message };
  }
  if (fluxAnyReconcilingWithBadConfig(fluxConditions)) {
    return {
      status: 'reconcilingWithBadConfig',
      message: fluxAnyReconcilingWithBadConfig(fluxConditions).message,
    };
  }
  if (fluxAnyReconciling(fluxConditions)) {
    return { status: 'reconciling' };
  }
  if (fluxAnyReconciled(fluxConditions)) {
    return { status: 'reconciled' };
  }
  return { status: 'unknown' };
};
