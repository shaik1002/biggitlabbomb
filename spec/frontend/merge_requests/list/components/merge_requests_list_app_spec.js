import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import {
  getQueryResponse,
  getCountsQueryResponse,
} from 'ee_else_ce_jest/merge_requests/list/mock_data';
import ApprovalCount from 'ee_else_ce/merge_requests/components/approval_count.vue';
import { STATUS_CLOSED, STATUS_OPEN, STATUS_MERGED } from '~/issues/constants';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import {
  TOKEN_TYPE_APPROVED_BY,
  TOKEN_TYPE_APPROVER,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_DRAFT,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MERGE_USER,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_SOURCE_BRANCH,
  TOKEN_TYPE_TARGET_BRANCH,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_REVIEWER,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_ENVIRONMENT,
  TOKEN_TYPE_DEPLOYED_AFTER,
  TOKEN_TYPE_DEPLOYED_BEFORE,
  OPERATOR_IS,
  OPERATOR_NOT,
} from '~/vue_shared/components/filtered_search_bar/constants';
import { mergeRequestListTabs } from '~/vue_shared/issuable/list/constants';
import { getSortOptions } from '~/issues/list/utils';
import MergeRequestsListApp from '~/merge_requests/list/components/merge_requests_list_app.vue';
import getMergeRequestsQuery from '~/merge_requests/list/queries/get_merge_requests.query.graphql';
import getMergeRequestsCountQuery from '~/merge_requests/list/queries/get_merge_requests_counts.query.graphql';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import issuableEventHub from '~/issues/list/eventhub';

Vue.use(VueApollo);
Vue.use(VueRouter);

let wrapper;
let router;
let getQueryResponseMock;
let getCountsQueryResponseMock;

const findIssuableList = () => wrapper.findComponent(IssuableList);
const findNewMrButton = () => wrapper.findByTestId('new-merge-request-button');
const findBulkEditButton = () => wrapper.findByTestId('bulk-edit');

function createComponent({
  provide = {},
  response = getQueryResponse,
  mountFn = shallowMountExtended,
} = {}) {
  getQueryResponseMock = jest.fn().mockResolvedValue(response);
  getCountsQueryResponseMock = jest.fn().mockResolvedValue(getCountsQueryResponse);
  const apolloProvider = createMockApollo([
    [getMergeRequestsCountQuery, getCountsQueryResponseMock],
    [getMergeRequestsQuery, getQueryResponseMock],
  ]);
  router = new VueRouter({ mode: 'history' });
  router.push = jest.fn();

  wrapper = mountFn(MergeRequestsListApp, {
    provide: {
      autocompleteAwardEmojisPath: 'pathy/pathface',
      fullPath: 'gitlab-org/gitlab',
      hasAnyMergeRequests: true,
      hasScopedLabelsFeature: false,
      initialSort: '',
      isPublicVisibilityRestricted: false,
      isSignedIn: true,
      newMergeRequestPath: '',
      releasesEndpoint: '',
      issuableType: 'merge_request',
      issuableCount: 1,
      email: '',
      exportCsvPath: '',
      rssUrl: '',
      canBulkUpdate: true,
      environmentNamesPath: '',
      ...provide,
    },
    apolloProvider,
    router,
  });
}

describe('Merge requests list app', () => {
  it('does not render issuable list if hasAnyMergeRequests is false', async () => {
    createComponent({ provide: { hasAnyMergeRequests: false } });

    await waitForPromises();

    expect(findIssuableList().exists()).toBe(false);
  });

  it('shows "New merge request" button', () => {
    createComponent({ provide: { newMergeRequestPath: '/new-mr-path' } });

    expect(findNewMrButton().exists()).toBe(true);
  });

  it('renders issuable list', async () => {
    createComponent();

    await waitForPromises();

    expect(findIssuableList().props()).toMatchObject({
      namespace: 'gitlab-org/gitlab',
      recentSearchesStorageKey: 'merge_requests',
      sortOptions: getSortOptions({ hasManualSort: false }),
      initialSortBy: 'CREATED_DESC',
      issuables: getQueryResponse.data.project.mergeRequests.nodes,
      tabs: mergeRequestListTabs,
      currentTab: 'opened',
      tabCounts: {
        opened: 1,
        merged: 1,
        closed: 1,
        all: 1,
      },
      issuablesLoading: false,
      isManualOrdering: false,
      showBulkEditSidebar: false,
      showPaginationControls: true,
      useKeysetPagination: true,
      hasPreviousPage: false,
      hasNextPage: true,
    });
  });

  describe('tokens', () => {
    const mockCurrentUser = {
      id: 1,
      name: 'Administrator',
      username: 'root',
      avatar_url: 'avatar/url',
    };

    describe('when user is signed out', () => {
      beforeEach(async () => {
        createComponent();

        await waitForPromises();
      });

      it('does not have preloaded users when gon.current_user_id does not exist', () => {
        expect(findIssuableList().props('searchTokens')).toMatchObject([
          { type: TOKEN_TYPE_APPROVED_BY, preloadedUsers: [] },
          { type: TOKEN_TYPE_APPROVER, preloadedUsers: [] },
          { type: TOKEN_TYPE_ASSIGNEE },
          { type: TOKEN_TYPE_REVIEWER, preloadedUsers: [] },
          { type: TOKEN_TYPE_AUTHOR, preloadedUsers: [] },
          { type: TOKEN_TYPE_DRAFT },
          { type: TOKEN_TYPE_MERGE_USER, preloadedUsers: [] },
          { type: TOKEN_TYPE_MILESTONE },
          { type: TOKEN_TYPE_TARGET_BRANCH },
          { type: TOKEN_TYPE_SOURCE_BRANCH },
          { type: TOKEN_TYPE_LABEL },
          { type: TOKEN_TYPE_RELEASE },
          { type: TOKEN_TYPE_ENVIRONMENT },
          { type: TOKEN_TYPE_DEPLOYED_BEFORE },
          { type: TOKEN_TYPE_DEPLOYED_AFTER },
          { type: TOKEN_TYPE_MY_REACTION },
        ]);
      });
    });

    describe('when all tokens are available', () => {
      const urlParams = {
        'approved_by_usernames[]': 'anthony',
        'approver[]': 'angus',
        assignee_username: 'bob',
        reviewer_username: 'bill',
        draft: 'yes',
        'label_name[]': 'fluff',
        merge_user: 'mallory',
        milestone_title: 'milestone',
        my_reaction_emoji: '🔥',
        'target_branches[]': 'branch-a',
        'source_branches[]': 'branch-b',
      };

      beforeEach(async () => {
        setWindowLocation(`?${new URLSearchParams(urlParams).toString()}`);
        window.gon = {
          current_user_id: mockCurrentUser.id,
          current_user_fullname: mockCurrentUser.name,
          current_username: mockCurrentUser.username,
          current_user_avatar_url: mockCurrentUser.avatar_url,
        };

        createComponent();

        await waitForPromises();
      });

      afterEach(() => {
        window.gon = {};
        setWindowLocation('?');
      });

      it('renders all tokens', () => {
        const preloadedUsers = [
          { ...mockCurrentUser, id: convertToGraphQLId(TYPENAME_USER, mockCurrentUser.id) },
        ];

        expect(findIssuableList().props('searchTokens')).toMatchObject([
          { type: TOKEN_TYPE_APPROVED_BY, preloadedUsers },
          { type: TOKEN_TYPE_APPROVER, preloadedUsers },
          { type: TOKEN_TYPE_ASSIGNEE },
          { type: TOKEN_TYPE_REVIEWER, preloadedUsers },
          { type: TOKEN_TYPE_AUTHOR, preloadedUsers },
          { type: TOKEN_TYPE_DRAFT },
          { type: TOKEN_TYPE_MERGE_USER, preloadedUsers },
          { type: TOKEN_TYPE_MILESTONE },
          { type: TOKEN_TYPE_TARGET_BRANCH },
          { type: TOKEN_TYPE_SOURCE_BRANCH },
          { type: TOKEN_TYPE_LABEL },
          { type: TOKEN_TYPE_RELEASE },
          { type: TOKEN_TYPE_ENVIRONMENT },
          { type: TOKEN_TYPE_DEPLOYED_BEFORE },
          { type: TOKEN_TYPE_DEPLOYED_AFTER },
          { type: TOKEN_TYPE_MY_REACTION },
        ]);
      });

      it('pre-displays tokens that are in the url search parameters', () => {
        expect(findIssuableList().props('initialFilterValue')).toMatchObject([
          { type: TOKEN_TYPE_APPROVED_BY },
          { type: TOKEN_TYPE_APPROVER },
          { type: TOKEN_TYPE_ASSIGNEE },
          { type: TOKEN_TYPE_REVIEWER },
          { type: TOKEN_TYPE_DRAFT },
          { type: TOKEN_TYPE_LABEL },
          { type: TOKEN_TYPE_MERGE_USER },
          { type: TOKEN_TYPE_MILESTONE },
          { type: TOKEN_TYPE_MY_REACTION },
          { type: TOKEN_TYPE_TARGET_BRANCH },
          { type: TOKEN_TYPE_SOURCE_BRANCH },
        ]);
      });
    });
  });

  describe('events', () => {
    describe('when "filter" event is emitted by IssuableList', () => {
      it('updates IssuableList with url params', async () => {
        createComponent();

        findIssuableList().vm.$emit('filter', [
          {
            type: 'assignee',
            value: { data: ['root'], operator: OPERATOR_IS },
          },
          {
            type: 'reviewer',
            value: { data: 'root', operator: OPERATOR_IS },
          },
        ]);
        await nextTick();

        expect(router.push).toHaveBeenCalledWith({
          query: expect.objectContaining({
            'assignee_username[]': ['root'],
            reviewer_username: 'root',
          }),
        });
      });

      it('fetches new data with "not" variable', async () => {
        createComponent();

        findIssuableList().vm.$emit('filter', [
          {
            type: 'assignee',
            value: { data: ['root'], operator: OPERATOR_NOT },
          },
          {
            type: 'reviewer',
            value: { data: 'root', operator: OPERATOR_NOT },
          },
        ]);

        await nextTick();

        expect(getQueryResponseMock).toHaveBeenCalledWith(
          expect.objectContaining({
            not: { assigneeUsernames: ['root'], reviewerUsername: 'root' },
          }),
        );

        expect(getCountsQueryResponseMock).toHaveBeenCalledWith(
          expect.objectContaining({
            not: { assigneeUsernames: ['root'], reviewerUsername: 'root' },
          }),
        );
      });

      it('pushes new route with "not" values', async () => {
        createComponent();

        findIssuableList().vm.$emit('filter', [
          {
            type: 'assignee',
            value: { data: ['root'], operator: OPERATOR_NOT },
          },
          {
            type: 'reviewer',
            value: { data: 'root', operator: OPERATOR_NOT },
          },
        ]);

        await nextTick();

        expect(router.push).toHaveBeenCalledWith({
          query: expect.objectContaining({
            'not[assignee_username][]': ['root'],
            'not[reviewer_username]': 'root',
          }),
        });
      });
    });
  });

  describe('cannot merge badge', () => {
    const findCannotMergeLink = () => wrapper.findByTestId('merge-request-cannot-merge');

    it.each`
      state            | cannotMergeProperties            | exists   | existsText
      ${STATUS_OPEN}   | ${{ commitCount: 0 }}            | ${true}  | ${'renders'}
      ${STATUS_CLOSED} | ${{ commitCount: 0 }}            | ${false} | ${'does not render'}
      ${STATUS_MERGED} | ${{ commitCount: 0 }}            | ${false} | ${'does not render'}
      ${STATUS_OPEN}   | ${{ sourceBranchExists: false }} | ${true}  | ${'renders'}
      ${STATUS_CLOSED} | ${{ sourceBranchExists: false }} | ${false} | ${'does not render'}
      ${STATUS_MERGED} | ${{ sourceBranchExists: false }} | ${false} | ${'does not render'}
      ${STATUS_OPEN}   | ${{ targetBranchExists: false }} | ${true}  | ${'renders'}
      ${STATUS_CLOSED} | ${{ targetBranchExists: false }} | ${false} | ${'does not render'}
      ${STATUS_MERGED} | ${{ targetBranchExists: false }} | ${false} | ${'does not render'}
      ${STATUS_OPEN}   | ${{ conflicts: true }}           | ${true}  | ${'renders'}
      ${STATUS_CLOSED} | ${{ conflicts: true }}           | ${false} | ${'does not render'}
      ${STATUS_MERGED} | ${{ conflicts: true }}           | ${false} | ${'does not render'}
    `(
      '$existsText cannot merge badge when state is $state and mergeRequest has $cannotMergeProperties',
      async ({ state, cannotMergeProperties, exists }) => {
        const response = JSON.parse(JSON.stringify(getQueryResponse));
        Object.assign(response.data.project.mergeRequests.nodes[0], {
          state,
          ...cannotMergeProperties,
        });

        createComponent({ mountFn: mountExtended, response });

        await waitForPromises();

        expect(findCannotMergeLink().exists()).toBe(exists);
      },
    );
  });

  it('renders approval count component', async () => {
    createComponent({ mountFn: mountExtended });

    await waitForPromises();

    expect(wrapper.findComponent(ApprovalCount).exists()).toBe(true);
    expect(wrapper.findComponent(ApprovalCount).props('mergeRequest')).toEqual(
      getQueryResponse.data.project.mergeRequests.nodes[0],
    );
  });

  describe('bulk edit', () => {
    it('renders when user has permissions', () => {
      createComponent({ provide: { canBulkUpdate: true }, mountFn: mountExtended });

      expect(findBulkEditButton().exists()).toBe(true);
    });

    it('does not render when user does not have permissions', () => {
      createComponent({ provide: { canBulkUpdate: false }, mountFn: mountExtended });

      expect(findBulkEditButton().exists()).toBe(false);
    });

    it('emits "issuables:enableBulkEdit" event to legacy bulk edit class', async () => {
      createComponent({ provide: { canBulkUpdate: true }, mountFn: mountExtended });
      jest.spyOn(issuableEventHub, '$emit');

      findBulkEditButton().vm.$emit('click');
      await waitForPromises();

      expect(issuableEventHub.$emit).toHaveBeenCalledWith('issuables:enableBulkEdit');
    });

    describe.each([true, false])(
      'when "issuables:toggleBulkEdit" event is received with payload `%s`',
      (isBulkEdit) => {
        beforeEach(() => {
          createComponent();

          issuableEventHub.$emit('issuables:toggleBulkEdit', isBulkEdit);
        });

        it(`${isBulkEdit ? 'enables' : 'disables'} bulk edit`, () => {
          expect(findIssuableList().props('showBulkEditSidebar')).toBe(isBulkEdit);
        });
      },
    );

    describe('when "update-legacy-bulk-edit" event is emitted by IssuableList', () => {
      beforeEach(() => {
        createComponent();
        jest.spyOn(issuableEventHub, '$emit');
      });

      it('emits an "issuables:updateBulkEdit" event to the legacy bulk edit class', async () => {
        findIssuableList().vm.$emit('update-legacy-bulk-edit');

        await nextTick();

        expect(issuableEventHub.$emit).toHaveBeenCalledWith('issuables:updateBulkEdit');
      });
    });
  });
});
