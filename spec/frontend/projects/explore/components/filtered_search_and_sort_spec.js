import { GlFilteredSearchToken } from '@gitlab/ui';
import {
  SORT_OPTION_NAME,
  SORT_OPTION_CREATED,
  SORT_OPTION_UPDATED,
  FILTERED_SEARCH_TERM_KEY,
  FILTERED_SEARCH_NAMESPACE,
  SORT_OPTIONS,
  SORT_DIRECTION_ASC,
  SORT_DIRECTION_DESC,
} from '~/projects/explore/constants';
import { RECENT_SEARCHES_STORAGE_KEY_PROJECTS } from '~/filtered_search/recent_searches_storage_keys';
import FilteredSearchAndSort from '~/groups_projects/components/filtered_search_and_sort.vue';
import ProjectsExploreFilteredSearchAndSort from '~/projects/explore/components/filtered_search_and_sort.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('ProjectsExploreFilteredSearchAndSort', () => {
  let wrapper;

  const defaultProvide = {
    initialSort: `${SORT_OPTION_NAME.value}_${SORT_DIRECTION_ASC}`,
    programmingLanguages: [
      { id: 5, name: 'CSS', color: '#563d7c', created_at: '2023-09-19T14:41:37.601Z' },
      { id: 8, name: 'CoffeeScript', color: '#244776', created_at: '2023-09-19T14:42:01.494Z' },
      { id: 1, name: 'HTML', color: '#e34c26', created_at: '2023-09-19T14:41:37.597Z' },
      { id: 7, name: 'JavaScript', color: '#f1e05a', created_at: '2023-09-19T14:42:01.494Z' },
      { id: 10, name: 'Makefile', color: '#427819', created_at: '2023-09-19T14:42:11.922Z' },
      { id: 6, name: 'Ruby', color: '#701516', created_at: '2023-09-19T14:42:01.493Z' },
      { id: 11, name: 'Shell', color: '#89e051', created_at: '2023-09-19T14:42:11.923Z' },
    ],
    starredExploreProjectsPath: '/explore/projects/starred',
    exploreRootPath: '/explore',
  };

  const createComponent = ({
    pathname = '/explore/projects',
    queryString = `?archived=only&${FILTERED_SEARCH_TERM_KEY}=foo&sort=${SORT_OPTION_CREATED.value}_${SORT_DIRECTION_ASC}&page=2`,
  } = {}) => {
    setWindowLocation(pathname + queryString);

    wrapper = shallowMountExtended(ProjectsExploreFilteredSearchAndSort, {
      provide: defaultProvide,
    });
  };

  const findFilteredSearchAndSort = () => wrapper.findComponent(FilteredSearchAndSort);

  it('renders filtered search bar with correct props', () => {
    createComponent();

    expect(findFilteredSearchAndSort().props()).toMatchObject({
      filteredSearchTokens: [
        {
          type: 'language',
          icon: 'lock',
          title: 'Language',
          token: GlFilteredSearchToken,
          unique: true,
          operators: [{ value: '=', description: 'is' }],
          options: [
            { value: '5', title: 'CSS' },
            { value: '8', title: 'CoffeeScript' },
            { value: '1', title: 'HTML' },
            { value: '7', title: 'JavaScript' },
            { value: '10', title: 'Makefile' },
            { value: '6', title: 'Ruby' },
            { value: '11', title: 'Shell' },
          ],
        },
      ],
      filteredSearchQuery: { [FILTERED_SEARCH_TERM_KEY]: 'foo' },
      filteredSearchTermKey: FILTERED_SEARCH_TERM_KEY,
      filteredSearchNamespace: FILTERED_SEARCH_NAMESPACE,
      filteredSearchRecentSearchesStorageKey: RECENT_SEARCHES_STORAGE_KEY_PROJECTS,
      sortOptions: SORT_OPTIONS,
      activeSortOption: SORT_OPTION_CREATED,
      isAscending: true,
    });
  });

  describe('when filtered search bar is submitted', () => {
    const searchTerm = 'foo bar';

    beforeEach(() => {
      createComponent();

      findFilteredSearchAndSort().vm.$emit('filter', {
        [FILTERED_SEARCH_TERM_KEY]: searchTerm,
        language: '5',
      });
    });

    it('visits URL with correct query string', () => {
      expect(visitUrl).toHaveBeenCalledWith(
        `?${FILTERED_SEARCH_TERM_KEY}=foo%20bar&language=5&sort=${SORT_OPTION_CREATED.value}_${SORT_DIRECTION_ASC}&archived=only`,
      );
    });
  });

  describe('when sort item is changed', () => {
    beforeEach(() => {
      createComponent();

      findFilteredSearchAndSort().vm.$emit('sort-by-change', SORT_OPTION_UPDATED.value);
    });

    it('visits URL with correct query string', () => {
      expect(visitUrl).toHaveBeenCalledWith(
        `?archived=only&${FILTERED_SEARCH_TERM_KEY}=foo&sort=${SORT_OPTION_UPDATED.value}_${SORT_DIRECTION_ASC}`,
      );
    });
  });

  describe('when sort direction is changed', () => {
    beforeEach(() => {
      createComponent();

      findFilteredSearchAndSort().vm.$emit('sort-direction-change', false);
    });

    it('visits URL with correct query string', () => {
      expect(visitUrl).toHaveBeenCalledWith(
        `?archived=only&${FILTERED_SEARCH_TERM_KEY}=foo&sort=${SORT_OPTION_CREATED.value}_${SORT_DIRECTION_DESC}`,
      );
    });
  });

  describe('when on the "Most starred" tab', () => {
    it.each([defaultProvide.starredExploreProjectsPath, defaultProvide.exploreRootPath])(
      'does not show sort dropdown',
      (pathname) => {
        createComponent({ pathname });

        expect(findFilteredSearchAndSort().props('sortOptions')).toEqual([]);
      },
    );
  });
});
