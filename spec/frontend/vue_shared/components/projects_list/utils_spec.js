import {
  availableGraphQLProjectActions,
  restoreProject,
} from '~/vue_shared/components/projects_list/utils';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';

describe('Projects list utils', () => {
  describe('restoreProject', () => {
    it('should throw an error with the correct message in CE', () => {
      expect(() => restoreProject()).toThrow(
        'Restoring a project is not available with your current license',
      );
    });
  });

  describe.each`
    userPermissions                                  | availableActions
    ${{ viewEditPage: false, removeProject: false }} | ${[]}
    ${{ viewEditPage: true, removeProject: false }}  | ${[ACTION_EDIT]}
    ${{ viewEditPage: false, removeProject: true }}  | ${[ACTION_DELETE]}
    ${{ viewEditPage: true, removeProject: true }}   | ${[ACTION_EDIT, ACTION_DELETE]}
  `('availableGraphQLProjectActions', ({ userPermissions, availableActions }) => {
    it(`when userPermissions = ${JSON.stringify(userPermissions)} then availableActions = [${availableActions}] and is sorted correctly`, () => {
      expect(availableGraphQLProjectActions({ userPermissions })).toStrictEqual(availableActions);
    });
  });
});
