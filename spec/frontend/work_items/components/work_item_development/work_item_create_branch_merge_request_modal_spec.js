import { GlForm, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import WorkItemCreateBranchMergeRequestModal from '~/work_items/components/work_item_development/work_item_create_branch_merge_request_modal.vue';
import { createAlert } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('CreateBranchMergeRequestModal', () => {
  let wrapper;
  let mock;
  const showToast = jest.fn();

  const createWrapper = ({
    workItemId = 'gid://gitlab/WorkItem/1',
    workItemIid = '1',
    branchFlow = true,
    mergeRequestFlow = false,
    showModal = true,
    workItemType = 'Issue',
  } = {}) => {
    wrapper = shallowMount(WorkItemCreateBranchMergeRequestModal, {
      propsData: {
        workItemId,
        workItemIid,
        workItemType,
        branchFlow,
        mergeRequestFlow,
        showModal,
      },
      provide: {
        canCreatePath: 'canCreatePath/1/path',
        fullPath: 'fullPath',
        defaultBranch: 'defaultBranch',
        createBranchPath: 'createBranchPath',
        createMrPath: 'createMrPath',
        refsPath: 'refsPath',
      },
      mocks: {
        $toast: {
          show: showToast,
        },
      },
    });
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findGlModal = () => wrapper.findComponent(GlModal);
  const firePrimaryEvent = () => findGlModal().vm.$emit('primary', { preventDefault: jest.fn() });

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet('canCreatePath/1/path').reply(HTTP_STATUS_OK, {
      can_create_branch: true,
      suggested_branch_name: 'suggested_branch_name',
    });
    return createWrapper();
  });

  afterEach(() => {
    mock.restore();
  });

  describe('on initialise', () => {
    it('shows the form', () => {
      expect(findForm().exists()).toBe(true);
    });
  });

  describe('Branch creation', () => {
    it('calls the create branch mutation with the correct parameters', async () => {
      createWrapper();
      await waitForPromises();

      jest.spyOn(axios, 'post');
      mock
        .onPost('createBranchPath?ref=defaultBranch&branch_name=suggested_branch_name')
        .reply(200, { data: { url: 'http://test.com/branch' } });

      firePrimaryEvent();
      await waitForPromises();

      expect(axios.post).toHaveBeenCalledWith(
        `createBranchPath?ref=defaultBranch&branch_name=suggested_branch_name`,
        {
          confidential_issue_project_id: null,
        },
      );
    });

    it('shows a success toast message when branch is created', async () => {
      createWrapper();
      await waitForPromises();

      mock
        .onPost('createBranchPath?ref=defaultBranch&branch_name=suggested_branch_name')
        .reply(200, { data: { url: 'http://test.com/branch' } });

      firePrimaryEvent();
      await waitForPromises();

      expect(showToast).toHaveBeenCalledWith('Branch created.', {
        autoHideDelay: 10000,
        action: {
          text: 'View branch',
          onClick: expect.any(Function),
        },
      });
    });

    it('shows an error alert when branch creation fails', async () => {
      mock
        .onPost('createBranchPath?ref=defaultBranch&branch_name=suggested_branch_name')
        .reply(422, { message: 'Error creating branch' });
      createWrapper();
      await waitForPromises();

      firePrimaryEvent();
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Failed to create a branch for this issue. Please try again.',
      });
    });
  });

  describe('Merge request creation', () => {
    it('redirects to the the merge branch mutation with the correct parameters', async () => {
      createWrapper({ branchFlow: false, mergeRequestFlow: true });
      await waitForPromises();

      jest.spyOn(axios, 'post');
      mock
        .onPost('createBranchPath?ref=defaultBranch&branch_name=suggested_branch_name')
        .reply(200, { data: { url: 'http://test.com/branch' } });

      firePrimaryEvent();
      await waitForPromises();

      expect(axios.post).toHaveBeenCalledWith(
        `createBranchPath?ref=defaultBranch&branch_name=suggested_branch_name`,
        {
          confidential_issue_project_id: null,
        },
      );

      await waitForPromises();

      expect(visitUrl).toHaveBeenCalled();
    });
  });
});
