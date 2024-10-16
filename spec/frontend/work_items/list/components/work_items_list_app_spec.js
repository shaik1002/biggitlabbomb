import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { cloneDeep } from 'lodash';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import IssueCardStatistics from 'ee_else_ce/issues/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/issues/list/components/issue_card_time_info.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  setSortPreferenceMutationResponse,
  setSortPreferenceMutationResponseWithErrors,
} from 'jest/issues/list/mock_data';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';
import { CREATED_DESC, UPDATED_DESC } from '~/issues/list/constants';
import setSortPreferenceMutation from '~/issues/list/queries/set_sort_preference.mutation.graphql';
import { scrollUp } from '~/lib/utils/scroll_utils';
import {
  FILTERED_SEARCH_TERM,
  OPERATOR_IS,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_SEARCH_WITHIN,
} from '~/vue_shared/components/filtered_search_bar/constants';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import WorkItemsListApp from '~/work_items/list/components/work_items_list_app.vue';
import { sortOptions, urlSortParams } from '~/work_items/list/constants';
import getWorkItemsQuery from '~/work_items/list/queries/get_work_items.query.graphql';
import { groupWorkItemsQueryResponse } from '../../mock_data';

jest.mock('~/lib/utils/scroll_utils', () => ({ scrollUp: jest.fn() }));
jest.mock('~/sentry/sentry_browser_wrapper');

describe('WorkItemsListApp component', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  Vue.use(VueApollo);

  const defaultQueryHandler = jest.fn().mockResolvedValue(groupWorkItemsQueryResponse);

  const findIssuableList = () => wrapper.findComponent(IssuableList);
  const findIssueCardStatistics = () => wrapper.findComponent(IssueCardStatistics);
  const findIssueCardTimeInfo = () => wrapper.findComponent(IssueCardTimeInfo);

  const mountComponent = ({
    provide = {},
    queryHandler = defaultQueryHandler,
    sortPreferenceMutationResponse = jest.fn().mockResolvedValue(setSortPreferenceMutationResponse),
  } = {}) => {
    wrapper = shallowMount(WorkItemsListApp, {
      apolloProvider: createMockApollo([
        [getWorkItemsQuery, queryHandler],
        [setSortPreferenceMutation, sortPreferenceMutationResponse],
      ]),
      provide: {
        fullPath: 'full/path',
        initialSort: CREATED_DESC,
        isSignedIn: true,
        workItemType: null,
        ...provide,
      },
    });
  };

  it('renders loading icon when initially fetching work items', () => {
    mountComponent();

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  describe('when work items are fetched', () => {
    beforeEach(async () => {
      mountComponent();
      await waitForPromises();
    });

    it('renders IssuableList component', () => {
      expect(findIssuableList().props()).toMatchObject({
        currentTab: STATUS_OPEN,
        error: '',
        initialSortBy: CREATED_DESC,
        namespace: 'work-items',
        recentSearchesStorageKey: 'issues',
        showWorkItemTypeIcon: true,
        sortOptions,
        tabs: WorkItemsListApp.issuableListTabs,
      });
    });

    it('renders tab counts', () => {
      expect(cloneDeep(findIssuableList().props('tabCounts'))).toEqual({
        all: 3,
        closed: 1,
        opened: 2,
      });
    });

    it('renders IssueCardStatistics component', () => {
      expect(findIssueCardStatistics().exists()).toBe(true);
    });

    it('renders IssueCardTimeInfo component', () => {
      expect(findIssueCardTimeInfo().exists()).toBe(true);
    });

    it('renders work items', () => {
      expect(findIssuableList().props('issuables')).toEqual(
        groupWorkItemsQueryResponse.data.group.workItems.nodes,
      );
    });

    it('calls query to fetch work items', () => {
      expect(defaultQueryHandler).toHaveBeenCalledWith({
        fullPath: 'full/path',
        sort: CREATED_DESC,
        state: STATUS_OPEN,
        firstPageSize: 20,
        types: [null],
      });
    });
  });

  describe('pagination controls', () => {
    describe.each`
      description                                                | pageInfo                                          | exists
      ${'when hasNextPage=true and hasPreviousPage=true'}        | ${{ hasNextPage: true, hasPreviousPage: true }}   | ${true}
      ${'when hasNextPage=true'}                                 | ${{ hasNextPage: true, hasPreviousPage: false }}  | ${true}
      ${'when hasPreviousPage=true'}                             | ${{ hasNextPage: false, hasPreviousPage: true }}  | ${true}
      ${'when neither hasNextPage nor hasPreviousPage are true'} | ${{ hasNextPage: false, hasPreviousPage: false }} | ${false}
    `('$description', ({ pageInfo, exists }) => {
      it(`${exists ? 'renders' : 'does not render'} pagination controls`, async () => {
        const response = cloneDeep(groupWorkItemsQueryResponse);
        Object.assign(response.data.group.workItems.pageInfo, pageInfo);
        mountComponent({ queryHandler: jest.fn().mockResolvedValue(response) });
        await waitForPromises();

        expect(findIssuableList().props('showPaginationControls')).toBe(exists);
      });
    });
  });

  describe('when workItemType is provided', () => {
    it('filters work items by workItemType', () => {
      const type = 'EPIC';
      mountComponent({ provide: { workItemType: type } });

      expect(defaultQueryHandler).toHaveBeenCalledWith({
        fullPath: 'full/path',
        sort: CREATED_DESC,
        state: STATUS_OPEN,
        firstPageSize: 20,
        types: [type],
      });
    });
  });

  describe('when there is an error fetching work items', () => {
    const message = 'Something went wrong when fetching work items. Please try again.';

    beforeEach(async () => {
      mountComponent({ queryHandler: jest.fn().mockRejectedValue(new Error('ERROR')) });
      await waitForPromises();
    });

    it('renders an error message', () => {
      expect(findIssuableList().props('error')).toBe(message);
      expect(Sentry.captureException).toHaveBeenCalledWith(new Error('ERROR'));
    });

    it('clears error message when "dismiss-alert" event is emitted from IssuableList', async () => {
      findIssuableList().vm.$emit('dismiss-alert');
      await nextTick();

      expect(wrapper.text()).not.toContain(message);
    });
  });

  describe('watcher', () => {
    describe('when eeCreatedWorkItemsCount is updated', () => {
      it('refetches work items', async () => {
        mountComponent();
        await waitForPromises();

        expect(defaultQueryHandler).toHaveBeenCalledTimes(1);

        await wrapper.setProps({ eeCreatedWorkItemsCount: 1 });

        expect(defaultQueryHandler).toHaveBeenCalledTimes(2);
      });
    });
  });

  describe('tokens', () => {
    const mockCurrentUser = {
      id: 1,
      name: 'Administrator',
      username: 'root',
      avatar_url: 'avatar/url',
    };

    beforeEach(async () => {
      window.gon = {
        current_user_id: mockCurrentUser.id,
        current_user_fullname: mockCurrentUser.name,
        current_username: mockCurrentUser.username,
        current_user_avatar_url: mockCurrentUser.avatar_url,
      };
      mountComponent();
      await waitForPromises();
    });

    it('renders all tokens', () => {
      const preloadedUsers = [
        { ...mockCurrentUser, id: convertToGraphQLId(TYPENAME_USER, mockCurrentUser.id) },
      ];

      expect(findIssuableList().props('searchTokens')).toMatchObject([
        { type: TOKEN_TYPE_AUTHOR, preloadedUsers },
        { type: TOKEN_TYPE_SEARCH_WITHIN },
      ]);
    });
  });

  describe('events', () => {
    describe('when "click-tab" event is emitted by IssuableList', () => {
      beforeEach(async () => {
        mountComponent();
        await waitForPromises();

        findIssuableList().vm.$emit('click-tab', STATUS_CLOSED);
      });

      it('updates ui to the new tab', () => {
        expect(findIssuableList().props('currentTab')).toBe(STATUS_CLOSED);
      });
    });

    describe('when "filter" event is emitted by IssuableList', () => {
      it('fetches filtered work items', async () => {
        mountComponent();
        await waitForPromises();

        findIssuableList().vm.$emit('filter', [
          { type: FILTERED_SEARCH_TERM, value: { data: 'find issues', operator: 'undefined' } },
          { type: TOKEN_TYPE_AUTHOR, value: { data: 'homer', operator: OPERATOR_IS } },
          { type: TOKEN_TYPE_SEARCH_WITHIN, value: { data: 'TITLE', operator: OPERATOR_IS } },
        ]);
        await nextTick();

        expect(defaultQueryHandler).toHaveBeenCalledWith({
          fullPath: 'full/path',
          sort: CREATED_DESC,
          state: STATUS_OPEN,
          search: 'find issues',
          authorUsername: 'homer',
          in: 'TITLE',
          firstPageSize: 20,
          types: [null],
        });
      });
    });

    describe.each`
      event              | params
      ${'next-page'}     | ${{ afterCursor: 'endCursor', firstPageSize: 20 }}
      ${'previous-page'} | ${{ beforeCursor: 'startCursor', lastPageSize: 20 }}
    `('when "$event" event is emitted by IssuableList', ({ event, params }) => {
      beforeEach(async () => {
        mountComponent();
        await waitForPromises();

        findIssuableList().vm.$emit(event);
      });

      it('scrolls to the top', () => {
        expect(scrollUp).toHaveBeenCalled();
      });

      it('fetches next/previous work items', () => {
        expect(defaultQueryHandler).toHaveBeenLastCalledWith(expect.objectContaining(params));
      });
    });

    describe('when "sort" event is emitted by IssuableList', () => {
      it.each(Object.keys(urlSortParams))(
        'updates to the new sort when payload is `%s`',
        async (sortKey) => {
          // Ensure initial sort key is different so we trigger an update when emitting a sort key
          if (sortKey === CREATED_DESC) {
            mountComponent({ provide: { initialSort: UPDATED_DESC } });
          } else {
            mountComponent();
          }
          await waitForPromises();

          findIssuableList().vm.$emit('sort', sortKey);
          await waitForPromises();

          expect(defaultQueryHandler).toHaveBeenCalledWith(
            expect.objectContaining({ sort: sortKey }),
          );
        },
      );

      describe('when user is signed in', () => {
        it('calls mutation to save sort preference', async () => {
          const mutationMock = jest.fn().mockResolvedValue(setSortPreferenceMutationResponse);
          mountComponent({ sortPreferenceMutationResponse: mutationMock });
          await waitForPromises();

          findIssuableList().vm.$emit('sort', UPDATED_DESC);

          expect(mutationMock).toHaveBeenCalledWith({ input: { issuesSort: UPDATED_DESC } });
        });

        it('captures error when mutation response has errors', async () => {
          const mutationMock = jest
            .fn()
            .mockResolvedValue(setSortPreferenceMutationResponseWithErrors);
          mountComponent({ sortPreferenceMutationResponse: mutationMock });
          await waitForPromises();

          findIssuableList().vm.$emit('sort', UPDATED_DESC);
          await waitForPromises();

          expect(Sentry.captureException).toHaveBeenCalledWith(new Error('oh no!'));
        });
      });

      describe('when user is signed out', () => {
        it('does not call mutation to save sort preference', async () => {
          const mutationMock = jest.fn().mockResolvedValue(setSortPreferenceMutationResponse);
          mountComponent({
            provide: { isSignedIn: false },
            sortPreferenceMutationResponse: mutationMock,
          });
          await waitForPromises();

          findIssuableList().vm.$emit('sort', CREATED_DESC);

          expect(mutationMock).not.toHaveBeenCalled();
        });
      });
    });
  });
});
