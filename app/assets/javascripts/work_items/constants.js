import { __, s__, sprintf } from '~/locale';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';

export const STATE_OPEN = 'OPEN';
export const STATE_CLOSED = 'CLOSED';

export const STATE_EVENT_REOPEN = 'REOPEN';
export const STATE_EVENT_CLOSE = 'CLOSE';

export const TRACKING_CATEGORY_SHOW = 'workItems:show';

export const WIDGET_TYPE_ASSIGNEES = 'ASSIGNEES';
export const WIDGET_TYPE_DESCRIPTION = 'DESCRIPTION';
export const WIDGET_TYPE_AWARD_EMOJI = 'AWARD_EMOJI';
export const WIDGET_TYPE_NOTIFICATIONS = 'NOTIFICATIONS';
export const WIDGET_TYPE_CURRENT_USER_TODOS = 'CURRENT_USER_TODOS';
export const WIDGET_TYPE_LABELS = 'LABELS';
export const WIDGET_TYPE_START_AND_DUE_DATE = 'START_AND_DUE_DATE';
export const WIDGET_TYPE_TIME_TRACKING = 'TIME_TRACKING';
export const WIDGET_TYPE_ROLLEDUP_DATES = 'ROLLEDUP_DATES';
export const WIDGET_TYPE_WEIGHT = 'WEIGHT';
export const WIDGET_TYPE_PARTICIPANTS = 'PARTICIPANTS';
export const WIDGET_TYPE_PROGRESS = 'PROGRESS';
export const WIDGET_TYPE_HIERARCHY = 'HIERARCHY';
export const WIDGET_TYPE_MILESTONE = 'MILESTONE';
export const WIDGET_TYPE_ITERATION = 'ITERATION';
export const WIDGET_TYPE_NOTES = 'NOTES';
export const WIDGET_TYPE_HEALTH_STATUS = 'HEALTH_STATUS';
export const WIDGET_TYPE_LINKED_ITEMS = 'LINKED_ITEMS';
export const WIDGET_TYPE_COLOR = 'COLOR';
export const WIDGET_TYPE_DESIGNS = 'DESIGNS';

export const WORK_ITEM_TYPE_ENUM_INCIDENT = 'INCIDENT';
export const WORK_ITEM_TYPE_ENUM_ISSUE = 'ISSUE';
export const WORK_ITEM_TYPE_ENUM_TASK = 'TASK';
export const WORK_ITEM_TYPE_ENUM_TEST_CASE = 'TEST_CASE';
export const WORK_ITEM_TYPE_ENUM_REQUIREMENTS = 'REQUIREMENT';
export const WORK_ITEM_TYPE_ENUM_OBJECTIVE = 'OBJECTIVE';
export const WORK_ITEM_TYPE_ENUM_KEY_RESULT = 'KEY_RESULT';
export const WORK_ITEM_TYPE_ENUM_EPIC = 'EPIC';

export const WORK_ITEM_TYPE_VALUE_EPIC = 'Epic';
export const WORK_ITEM_TYPE_VALUE_INCIDENT = 'Incident';
export const WORK_ITEM_TYPE_VALUE_ISSUE = 'Issue';
export const WORK_ITEM_TYPE_VALUE_TASK = 'Task';
export const WORK_ITEM_TYPE_VALUE_TEST_CASE = 'Test case';
export const WORK_ITEM_TYPE_VALUE_REQUIREMENTS = 'Requirements';
export const WORK_ITEM_TYPE_VALUE_KEY_RESULT = 'Key Result';
export const WORK_ITEM_TYPE_VALUE_OBJECTIVE = 'Objective';

export const WORK_ITEM_TITLE_MAX_LENGTH = 255;

export const WORK_ITEM_ROUTE_NAME = 'workItem';
export const DESIGN_ROUTE_NAME = 'design';

export const i18n = {
  fetchErrorTitle: s__('WorkItem|Work item not found'),
  fetchError: s__(
    "WorkItem|This work item is not available. It either doesn't exist or you don't have permission to view it.",
  ),
  updateError: s__('WorkItem|Something went wrong while updating the work item. Please try again.'),
};

export const I18N_WORK_ITEM_ERROR_FETCHING_LABELS = s__(
  'WorkItem|Something went wrong when fetching labels. Please try again.',
);
export const I18N_WORK_ITEM_ERROR_FETCHING_TYPES = s__(
  'WorkItem|Something went wrong when fetching work item types. Please try again',
);
export const I18N_WORK_ITEM_ERROR_CREATING = s__(
  'WorkItem|Something went wrong when creating %{workItemType}. Please try again.',
);
export const I18N_WORK_ITEM_ERROR_UPDATING = s__(
  'WorkItem|Something went wrong while updating the %{workItemType}. Please try again.',
);
export const I18N_WORK_ITEM_ERROR_CONVERTING = s__(
  'WorkItem|Something went wrong while promoting the %{workItemType}. Please try again.',
);
export const I18N_WORK_ITEM_ERROR_DELETING = s__(
  'WorkItem|Something went wrong when deleting the %{workItemType}. Please try again.',
);
export const I18N_WORK_ITEM_DELETE = s__('WorkItem|Delete %{workItemType}');
export const I18N_WORK_ITEM_ARE_YOU_SURE_DELETE = s__(
  'WorkItem|Are you sure you want to delete the %{workItemType}? This action cannot be reversed.',
);
export const I18N_WORK_ITEM_ARE_YOU_SURE_DELETE_HIERARCHY = s__(
  'WorkItem|Delete this %{workItemType} and release all child items? This action cannot be reversed.',
);
export const I18N_WORK_ITEM_CREATED = s__('WorkItem|%{workItemType} created');
export const I18N_WORK_ITEM_DELETED = s__('WorkItem|%{workItemType} deleted');

export const I18N_WORK_ITEM_FETCH_ITERATIONS_ERROR = s__(
  'WorkItem|Something went wrong when fetching iterations. Please try again.',
);

export const I18N_WORK_ITEM_FETCH_AWARD_EMOJI_ERROR = s__(
  'WorkItem|Something went wrong while fetching work item award emojis. Please try again.',
);

export const I18N_NEW_WORK_ITEM_BUTTON_LABEL = s__('WorkItem|New %{workItemType}');
export const I18N_WORK_ITEM_CREATE_BUTTON_LABEL = s__('WorkItem|Create %{workItemType}');
export const I18N_WORK_ITEM_ADD_BUTTON_LABEL = s__('WorkItem|Add %{workItemType}');
export const I18N_WORK_ITEM_ADD_MULTIPLE_BUTTON_LABEL = s__('WorkItem|Add %{workItemType}s');
export const I18N_WORK_ITEM_SEARCH_INPUT_PLACEHOLDER = s__(
  'WorkItem|Search existing items, paste URL, or enter reference ID',
);
export const I18N_WORK_ITEM_SEARCH_ERROR = s__(
  'WorkItem|Something went wrong while fetching the %{workItemType}. Please try again.',
);
export const I18N_WORK_ITEM_NO_MATCHES_FOUND = s__('WorkItem|No matches found');
export const I18N_WORK_ITEM_CONFIDENTIALITY_CHECKBOX_LABEL = s__(
  'WorkItem|This %{workItemType} is confidential and should only be visible to team members with at least Reporter access',
);
export const I18N_WORK_ITEM_CONFIDENTIALITY_CHECKBOX_TOOLTIP = s__(
  'WorkItem|A non-confidential %{workItemType} cannot be assigned to a confidential parent %{parentWorkItemType}.',
);

export const I18N_WORK_ITEM_ERROR_COPY_REFERENCE = s__(
  'WorkItem|Something went wrong while copying the %{workItemType} reference. Please try again.',
);
export const I18N_WORK_ITEM_ERROR_COPY_EMAIL = s__(
  'WorkItem|Something went wrong while copying the %{workItemType} email address. Please try again.',
);

export const I18N_MAX_CHARS_IN_WORK_ITEM_TITLE_MESSAGE = sprintf(
  s__('WorkItem|Title cannot have more than %{WORK_ITEM_TITLE_MAX_LENGTH} characters.'),
  { WORK_ITEM_TITLE_MAX_LENGTH },
);

export const I18N_WORK_ITEM_COPY_CREATE_NOTE_EMAIL = s__(
  'WorkItem|Copy %{workItemType} email address',
);

export const MAX_WORK_ITEMS = 10;

export const I18N_MAX_WORK_ITEMS_ERROR_MESSAGE = sprintf(
  s__('WorkItem|Only %{MAX_WORK_ITEMS} items can be added at a time.'),
  { MAX_WORK_ITEMS },
);
export const I18N_MAX_WORK_ITEMS_NOTE_LABEL = sprintf(
  s__('WorkItem|Add a maximum of %{MAX_WORK_ITEMS} items at a time.'),
  { MAX_WORK_ITEMS },
);
export const I18N_WORK_ITEM_SHOW_LABELS = s__('WorkItem|Show labels');

export const sprintfWorkItem = (msg, workItemTypeArg, parentWorkItemType = '') => {
  const workItemType = workItemTypeArg || s__('WorkItem|item');
  return capitalizeFirstCharacter(
    sprintf(msg, {
      workItemType: workItemType.toLocaleLowerCase(),
      parentWorkItemType: parentWorkItemType.toLocaleLowerCase(),
    }),
  );
};

export const WIDGET_ICONS = {
  TASK: 'issue-type-task',
};

export const WORK_ITEM_STATUS_TEXT = {
  CLOSED: s__('WorkItem|Closed'),
  OPEN: s__('WorkItem|Open'),
};

export const WORK_ITEMS_TYPE_MAP = {
  [WORK_ITEM_TYPE_ENUM_INCIDENT]: {
    icon: `issue-type-incident`,
    name: s__('WorkItem|Incident'),
    value: WORK_ITEM_TYPE_VALUE_INCIDENT,
  },
  [WORK_ITEM_TYPE_ENUM_ISSUE]: {
    icon: `issue-type-issue`,
    name: s__('WorkItem|Issue'),
    value: WORK_ITEM_TYPE_VALUE_ISSUE,
  },
  [WORK_ITEM_TYPE_ENUM_TASK]: {
    icon: `issue-type-task`,
    name: s__('WorkItem|Task'),
    value: WORK_ITEM_TYPE_VALUE_TASK,
  },
  [WORK_ITEM_TYPE_ENUM_TEST_CASE]: {
    icon: `issue-type-test-case`,
    name: s__('WorkItem|Test case'),
    value: WORK_ITEM_TYPE_VALUE_TEST_CASE,
  },
  [WORK_ITEM_TYPE_ENUM_REQUIREMENTS]: {
    icon: `issue-type-requirements`,
    name: s__('WorkItem|Requirements'),
    value: WORK_ITEM_TYPE_VALUE_REQUIREMENTS,
  },
  [WORK_ITEM_TYPE_ENUM_OBJECTIVE]: {
    icon: `issue-type-objective`,
    name: s__('WorkItem|Objective'),
    value: WORK_ITEM_TYPE_VALUE_OBJECTIVE,
  },
  [WORK_ITEM_TYPE_ENUM_KEY_RESULT]: {
    icon: `issue-type-keyresult`,
    name: s__('WorkItem|Key result'),
    value: WORK_ITEM_TYPE_VALUE_KEY_RESULT,
  },
  [WORK_ITEM_TYPE_ENUM_EPIC]: {
    icon: `epic`,
    name: s__('WorkItem|Epic'),
    value: WORK_ITEM_TYPE_VALUE_EPIC,
  },
};

export const WORK_ITEM_TYPE_VALUE_MAP = {
  [WORK_ITEM_TYPE_VALUE_OBJECTIVE]: WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  [WORK_ITEM_TYPE_VALUE_KEY_RESULT]: WORK_ITEM_TYPE_ENUM_KEY_RESULT,
  [WORK_ITEM_TYPE_VALUE_ISSUE]: WORK_ITEM_TYPE_ENUM_ISSUE,
  [WORK_ITEM_TYPE_VALUE_EPIC]: WORK_ITEM_TYPE_ENUM_EPIC,
};

export const WORK_ITEMS_TREE_TEXT_MAP = {
  [WORK_ITEM_TYPE_VALUE_OBJECTIVE]: {
    title: s__('WorkItem|Child objectives and key results'),
    empty: s__('WorkItem|No objectives or key results are currently assigned.'),
  },
  [WORK_ITEM_TYPE_VALUE_ISSUE]: {
    title: s__('WorkItem|Tasks'),
    empty: s__(
      'WorkItem|No tasks are currently assigned. Use tasks to break down this issue into smaller parts.',
    ),
  },
  [WORK_ITEM_TYPE_VALUE_EPIC]: {
    title: s__('WorkItem|Child items'),
    empty: s__('WorkItem|No epics or issues are currently assigned.'),
  },
};

export const FORM_TYPES = {
  create: 'create',
  add: 'add',
  [WORK_ITEM_TYPE_ENUM_OBJECTIVE]: {
    icon: `issue-type-issue`,
    name: s__('WorkItem|Objective'),
  },
};

export const DEFAULT_PAGE_SIZE_ASSIGNEES = 10;
export const DEFAULT_PAGE_SIZE_NOTES = 30;
export const DEFAULT_PAGE_SIZE_EMOJIS = 100;

export const WORK_ITEM_NOTES_SORT_ORDER_KEY = 'sort_direction_work_item';

export const WORK_ITEM_NOTES_FILTER_ALL_NOTES = 'ALL_NOTES';
export const WORK_ITEM_NOTES_FILTER_ONLY_COMMENTS = 'ONLY_COMMENTS';
export const WORK_ITEM_NOTES_FILTER_ONLY_HISTORY = 'ONLY_HISTORY';

export const WORK_ITEM_NOTES_FILTER_KEY = 'filter_key_work_item';

export const WORK_ITEM_ACTIVITY_FILTER_OPTIONS = [
  {
    value: WORK_ITEM_NOTES_FILTER_ALL_NOTES,
    text: s__('WorkItem|All activity'),
  },
  {
    value: WORK_ITEM_NOTES_FILTER_ONLY_COMMENTS,
    text: s__('WorkItem|Comments only'),
  },
  {
    value: WORK_ITEM_NOTES_FILTER_ONLY_HISTORY,
    text: s__('WorkItem|History only'),
  },
];

export const WORK_ITEM_ACTIVITY_SORT_OPTIONS = [
  { value: 'desc', text: __('Newest first') },
  { value: 'asc', text: __('Oldest first') },
];

export const TEST_ID_CONFIDENTIALITY_TOGGLE_ACTION = 'confidentiality-toggle-action';
export const TEST_ID_NOTIFICATIONS_TOGGLE_FORM = 'notifications-toggle-form';
export const TEST_ID_DELETE_ACTION = 'delete-action';
export const TEST_ID_PROMOTE_ACTION = 'promote-action';
export const TEST_ID_LOCK_ACTION = 'lock-action';
export const TEST_ID_COPY_REFERENCE_ACTION = 'copy-reference-action';
export const TEST_ID_COPY_CREATE_NOTE_EMAIL_ACTION = 'copy-create-note-email-action';
export const TEST_ID_TOGGLE_ACTION = 'state-toggle-action';

export const TODO_ADD_ICON = 'todo-add';
export const TODO_DONE_ICON = 'todo-done';
export const TODO_DONE_STATE = 'done';
export const TODO_PENDING_STATE = 'pending';

export const EMOJI_THUMBSUP = 'thumbsup';
export const EMOJI_THUMBSDOWN = 'thumbsdown';

export const WORK_ITEM_TO_ISSUE_MAP = {
  [WIDGET_TYPE_ASSIGNEES]: 'assignees',
  [WIDGET_TYPE_LABELS]: 'labels',
  [WIDGET_TYPE_MILESTONE]: 'milestone',
  [WIDGET_TYPE_WEIGHT]: 'weight',
  [WIDGET_TYPE_START_AND_DUE_DATE]: 'dueDate',
  [WIDGET_TYPE_HEALTH_STATUS]: 'healthStatus',
  [WIDGET_TYPE_AWARD_EMOJI]: 'awardEmoji',
};

export const LINKED_CATEGORIES_MAP = {
  RELATES_TO: 'relates_to',
  IS_BLOCKED_BY: 'is_blocked_by',
  BLOCKS: 'blocks',
};

export const LINKED_ITEM_TYPE_VALUE = {
  RELATED: 'RELATED',
  BLOCKED_BY: 'BLOCKED_BY',
  BLOCKS: 'BLOCKS',
};

export const LINK_ITEM_FORM_HEADER_LABEL = {
  [WORK_ITEM_TYPE_VALUE_OBJECTIVE]: s__('WorkItem|The current objective'),
  [WORK_ITEM_TYPE_VALUE_KEY_RESULT]: s__('WorkItem|The current key result'),
  [WORK_ITEM_TYPE_VALUE_TASK]: s__('WorkItem|The current task'),
};

export const SUPPORTED_PARENT_TYPE_MAP = {
  [WORK_ITEM_TYPE_VALUE_OBJECTIVE]: [WORK_ITEM_TYPE_ENUM_OBJECTIVE],
  [WORK_ITEM_TYPE_VALUE_KEY_RESULT]: [WORK_ITEM_TYPE_ENUM_OBJECTIVE],
  [WORK_ITEM_TYPE_VALUE_TASK]: [WORK_ITEM_TYPE_ENUM_ISSUE],
  [WORK_ITEM_TYPE_VALUE_EPIC]: [WORK_ITEM_TYPE_ENUM_EPIC],
};

export const LINKED_ITEMS_ANCHOR = 'linkeditems';
export const CHILD_ITEMS_ANCHOR = 'childitems';
export const TASKS_ANCHOR = 'tasks';

export const ISSUABLE_EPIC = 'issue-type-epic';

export const EPIC_COLORS = [
  { '#1068bf': s__('WorkItem|Blue') },
  { '#217645': s__('WorkItem|Forest green') },
  { '#c91c00': s__('WorkItem|Dark red') },
  { '#9e5400': s__('WorkItem|Coffee') },
  { '#694cc0': s__('WorkItem|Purple') },
  { '#de198f': s__('WorkItem|Magenta') },
  { '#2e90a5': s__('WorkItem|Teal') },
  { '#55aafe': s__('WorkItem|Light blue') },
  { '#4dd787': s__('WorkItem|Mint green') },
  { '#f17763': s__('WorkItem|Rose') },
  { '#f3ad5d': s__('WorkItem|Apricot') },
  { '#b7a0fd': s__('WorkItem|Lavender') },
  { '#fd8cd0': s__('WorkItem|Pink') },
  { '#6cd3ea': s__('WorkItem|Aqua') },
];

export const DEFAULT_EPIC_COLORS = '#1068bf';

export const CREATE_NEW_WORK_ITEM_MODAL = 'create_new_work_item_modal';
