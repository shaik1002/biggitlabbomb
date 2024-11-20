import { s__ } from '~/locale';

export const TODO_STATE_DONE = 'done';
export const TODO_STATE_PENDING = 'pending';

export const TODO_TARGET_TYPE_ISSUE = 'ISSUE';
export const TODO_TARGET_TYPE_WORK_ITEM = 'WORKITEM';
export const TODO_TARGET_TYPE_MERGE_REQUEST = 'MERGEREQUEST';
export const TODO_TARGET_TYPE_DESIGN = 'DESIGN';
export const TODO_TARGET_TYPE_ALERT = 'ALERT';
export const TODO_TARGET_TYPE_EPIC = 'EPIC';
export const TODO_TARGET_TYPE_SSH_KEY = 'KEY';

export const TODO_ACTION_TYPE_ASSIGNED = 'assigned';
export const TODO_ACTION_TYPE_MENTIONED = 'mentioned';
export const TODO_ACTION_TYPE_BUILD_FAILED = 'build_failed';
export const TODO_ACTION_TYPE_MARKED = 'marked';
export const TODO_ACTION_TYPE_APPROVAL_REQUIRED = 'approval_required';
export const TODO_ACTION_TYPE_UNMERGEABLE = 'unmergeable';
export const TODO_ACTION_TYPE_DIRECTLY_ADDRESSED = 'directly_addressed';
export const TODO_ACTION_TYPE_MERGE_TRAIN_REMOVED = 'merge_train_removed';
export const TODO_ACTION_TYPE_REVIEW_REQUESTED = 'review_requested';
export const TODO_ACTION_TYPE_MEMBER_ACCESS_REQUESTED = 'member_access_requested';
export const TODO_ACTION_TYPE_REVIEW_SUBMITTED = 'review_submitted';
export const TODO_ACTION_TYPE_OKR_CHECKIN_REQUESTED = 'okr_checkin_requested';
export const TODO_ACTION_TYPE_ADDED_APPROVER = 'added_approver';
export const TODO_ACTION_TYPE_SSH_KEY_EXPIRED = 'ssh_key_expired';

export const TODO_EMPTY_TITLE_POOL = [
  s__("Todos|Good job! Looks like you don't have anything left on your To-Do List"),
  s__("Todos|Isn't an empty To-Do List beautiful?"),
  s__('Todos|Give yourself a pat on the back!'),
  s__('Todos|Nothing left to do. High five!'),
  s__('Todos|Henceforth, you shall be known as "To-Do Destroyer"'),
];
