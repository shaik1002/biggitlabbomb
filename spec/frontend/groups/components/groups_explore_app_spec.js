import App from '~/groups/components/groups_explore_app.vue';
import { createRouter } from '~/groups/init_groups_explore';
import {
  SORTING_ITEM_CREATED,
  SORTING_ITEM_UPDATED,
  EXPLORE_SORTING_ITEMS,
  EXPLORE_FILTERED_SEARCH_TERM_KEY,
  EXPLORE_FILTERED_SEARCH_NAMESPACE,
} from '~/groups/constants';
import { RECENT_SEARCHES_STORAGE_KEY_GROUPS } from '~/filtered_search/recent_searches_storage_keys';
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
import GroupsApp from '~/groups/components/app.vue';
import EmptyState from '~/groups/components/empty_states/groups_explore_empty_state.vue';
import GroupsService from '~/groups/service/groups_service';
import GroupsStore from '~/groups/store/groups_store';
import eventHub from '~/groups/event_hub';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('GroupsExploreApp', () => {
  const router = createRouter();
  const routerMock = {
    push: jest.fn(),
  };

  let wrapper;

  const defaultProvide = {
    endpoint: '/explore/groups.json',
    initialSort: SORTING_ITEM_UPDATED.asc,
  };

  const createComponent = ({ routeQuery = { [EXPLORE_FILTERED_SEARCH_TERM_KEY]: 'foo' } } = {}) => {
    wrapper = shallowMountExtended(App, {
      router,
      mocks: { $route: { path: '/', query: routeQuery }, $router: routerMock },
      provide: defaultProvide,
    });
  };

  const findFilteredSearchAndSort = () => wrapper.findComponent(FilteredSearchAndSort);

  it('renders filtered search bar with correct props', () => {
    createComponent();

    expect(findFilteredSearchAndSort().props()).toMatchObject({
      filteredSearchTokens: [],
      filteredSearchQuery: { [EXPLORE_FILTERED_SEARCH_TERM_KEY]: 'foo' },
      filteredSearchTermKey: EXPLORE_FILTERED_SEARCH_TERM_KEY,
      filteredSearchNamespace: EXPLORE_FILTERED_SEARCH_NAMESPACE,
      filteredSearchRecentSearchesStorageKey: RECENT_SEARCHES_STORAGE_KEY_GROUPS,
      sortOptions: EXPLORE_SORTING_ITEMS.map((sortItem) => ({
        value: sortItem.asc,
        text: sortItem.label,
      })),
      activeSortOption: {
        value: SORTING_ITEM_UPDATED.asc,
        text: SORTING_ITEM_UPDATED.label,
      },
      isAscending: true,
    });
  });

  it('renders `GroupsApp` and empty state', () => {
    createComponent();

    const service = new GroupsService(defaultProvide.endpoint);
    const store = new GroupsStore({ hideProjects: true });

    expect(wrapper.findComponent(GroupsApp).props()).toMatchObject({
      service,
      store,
    });
    expect(wrapper.findComponent(EmptyState).exists()).toBe(true);
  });

  describe('when filtered search bar is submitted', () => {
    const searchTerm = 'foo bar';

    beforeEach(() => {
      jest.spyOn(eventHub, '$emit');
      createComponent();

      findFilteredSearchAndSort().vm.$emit('filter', {
        [EXPLORE_FILTERED_SEARCH_TERM_KEY]: searchTerm,
      });
    });

    it(`updates \`${EXPLORE_FILTERED_SEARCH_TERM_KEY}\` query string`, () => {
      expect(routerMock.push).toHaveBeenCalledWith({
        query: { [EXPLORE_FILTERED_SEARCH_TERM_KEY]: searchTerm },
      });
    });

    it('emits `fetchFilteredAndSortedGroups` with correct arguments', () => {
      expect(eventHub.$emit).toHaveBeenCalledWith('fetchFilteredAndSortedGroups', {
        filterGroupsBy: searchTerm,
        sortBy: defaultProvide.initialSort,
      });
    });
  });

  describe('when filtered search bar is cleared', () => {
    beforeEach(() => {
      createComponent();

      findFilteredSearchAndSort().vm.$emit('filter', {
        [EXPLORE_FILTERED_SEARCH_TERM_KEY]: '',
      });
    });

    it(`removes \`${EXPLORE_FILTERED_SEARCH_TERM_KEY}\` query string`, () => {
      expect(routerMock.push).toHaveBeenCalledWith({
        query: {},
      });
    });
  });

  describe('when sort item is changed', () => {
    beforeEach(() => {
      createComponent({
        routeQuery: {
          [EXPLORE_FILTERED_SEARCH_TERM_KEY]: 'foo',
        },
      });

      findFilteredSearchAndSort().vm.$emit('sort-by-change', SORTING_ITEM_CREATED.asc);
    });

    it('updates `sort` query string', () => {
      expect(routerMock.push).toHaveBeenCalledWith({
        query: {
          sort: SORTING_ITEM_CREATED.asc,
          [EXPLORE_FILTERED_SEARCH_TERM_KEY]: 'foo',
        },
      });
    });
  });

  describe('when sort direction is changed', () => {
    beforeEach(() => {
      createComponent({
        routeQuery: {
          [EXPLORE_FILTERED_SEARCH_TERM_KEY]: 'foo',
        },
      });

      findFilteredSearchAndSort().vm.$emit('sort-direction-change', false);
    });

    it('updates `sort` query string', () => {
      expect(routerMock.push).toHaveBeenCalledWith({
        query: {
          sort: SORTING_ITEM_UPDATED.desc,
          [EXPLORE_FILTERED_SEARCH_TERM_KEY]: 'foo',
        },
      });
    });
  });
});
