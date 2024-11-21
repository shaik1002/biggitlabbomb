import { s__ } from '~/locale';
import {
  ACTION_EDIT,
  ACTION_DELETE,
  BASE_ACTIONS,
} from '~/vue_shared/components/list_actions/constants';

//
export const restoreProject = () => {
  // Overridden in EE
  throw new Error(s__('Projects|Restoring a project is not available with your current license'));
};

export const availableGraphQLProjectActions = ({ userPermissions }) => {
  const baseActions = [];

  if (userPermissions.viewEditPage) {
    baseActions.push(ACTION_EDIT);
  }

  if (userPermissions.removeProject) {
    baseActions.push(ACTION_DELETE);
  }

  return baseActions.sort((a, b) => BASE_ACTIONS[a].order - BASE_ACTIONS[b].order);
};
