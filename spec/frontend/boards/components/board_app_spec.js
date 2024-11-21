import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BoardApp from '~/boards/components/board_app.vue';
import BoardTopBar from '~/boards/components/board_top_bar.vue';
import activeBoardItemQuery from 'ee_else_ce/boards/graphql/client/active_board_item.query.graphql';
import boardListsQuery from 'ee_else_ce/boards/graphql/board_lists.query.graphql';
import * as cacheUpdates from '~/boards/graphql/cache_updates';
import { rawIssue, boardListsQueryResponse } from '../mock_data';

describe('BoardApp', () => {
  let wrapper;
  let mockApollo;

  const findBoardTopBar = () => wrapper.findComponent(BoardTopBar);

  const errorMessage = 'Failed to fetch lists';
  const boardListQueryHandler = jest.fn().mockResolvedValue(boardListsQueryResponse);
  const boardListQueryHandlerFailure = jest.fn().mockRejectedValue(new Error(errorMessage));

  Vue.use(VueApollo);

  const createComponent = ({ issue = rawIssue, handler = boardListQueryHandler } = {}) => {
    mockApollo = createMockApollo([[boardListsQuery, handler]]);
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: activeBoardItemQuery,
      data: {
        activeBoardItem: { ...issue, listId: 'gid://gitlab/List/1' },
      },
    });

    wrapper = shallowMount(BoardApp, {
      apolloProvider: mockApollo,
      provide: {
        fullPath: 'gitlab-org',
        initialBoardId: 'gid://gitlab/Board/1',
        initialFilterParams: {},
        issuableType: 'issue',
        boardType: 'project',
        isIssueBoard: true,
        isGroupBoard: false,
      },
    });
  };

  beforeEach(async () => {
    cacheUpdates.setError = jest.fn();

    createComponent();
    await nextTick();
  });

  it('fetches lists', () => {
    expect(boardListQueryHandler).toHaveBeenCalled();
  });

  it('should have is-compact class when a card is selected', () => {
    expect(wrapper.classes()).toContain('is-compact');
  });

  it('should not have is-compact class when no card is selected', async () => {
    createComponent({ issue: {} });
    await nextTick();

    expect(wrapper.classes()).not.toContain('is-compact');
  });

  it('refetches lists when top bar emits updateBoard event', async () => {
    createComponent();
    await waitForPromises();
    findBoardTopBar().vm.$emit('updateBoard');

    expect(boardListQueryHandler).toHaveBeenCalled();
  });

  it('sets error on fetch lists failure', async () => {
    createComponent({ handler: boardListQueryHandlerFailure });

    await waitForPromises();

    expect(cacheUpdates.setError).toHaveBeenCalled();
  });
});
