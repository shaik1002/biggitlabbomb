import { __, s__ } from '~/locale';

export const COMMIT_BOX_POLL_INTERVAL = 10000;

export const PIPELINE_STATUS_FETCH_ERROR = __(
  'There was a problem fetching the latest pipeline status.',
);

export const BRANCHES = s__('Commit|Branches');

export const TAGS = s__('Commit|Tags');

export const CONTAINING_COMMIT = s__('Commit|containing commit');

export const FETCH_CONTAINING_REFS_EVENT = 'fetch-containing-refs';

export const FETCH_COMMIT_REFERENCES_ERROR = s__(
  'Commit|There was an error fetching the commit references. Please try again later.',
);

export const BRANCHES_REF_TYPE = 'heads';

export const TAGS_REF_TYPE = 'tags';
