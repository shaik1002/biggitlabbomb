export const jobStatusValues = [
  'CANCELED',
  'CREATED',
  'FAILED',
  'MANUAL',
  'SUCCESS',
  'PENDING',
  'PREPARING',
  'RUNNING',
  'SCHEDULED',
  'SKIPPED',
  'WAITING_FOR_RESOURCE',
];

export const jobSourceValues = [
  'api',
  'chat',
  'external',
  'external_pull_request_event',
  'merge_request_event',
  'ondemand_dast_scan',
  'ondemand_dast_validation',
  'parent_pipeline',
  'pipeline',
  'push',
  'schedule',
  'security_orchestration_policy',
  'trigger',
  'web',
  'webide',
  'scan_execution_policy',
  'pipeline_execution_policy',
];

export const JOB_RUNNER_TYPE_INSTANCE_TYPE = 'INSTANCE_TYPE';
export const JOB_RUNNER_TYPE_GROUP_TYPE = 'GROUP_TYPE';
export const JOB_RUNNER_TYPE_PROJECT_TYPE = 'PROJECT_TYPE';

export const jobRunnerTypeValues = [
  JOB_RUNNER_TYPE_INSTANCE_TYPE,
  JOB_RUNNER_TYPE_GROUP_TYPE,
  JOB_RUNNER_TYPE_PROJECT_TYPE,
];
