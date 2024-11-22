import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import MockAdapter from 'axios-mock-adapter';
import { GlFormCheckbox } from '@gitlab/ui';
import AjaxCache from '~/lib/utils/ajax_cache';
import axios from '~/lib/utils/axios_utils';
import AuthorFilter from '~/search/sidebar/components/author_filter/index.vue';
import FilterDropdown from '~/search/sidebar/components/shared/filter_dropdown.vue';
import { MOCK_QUERY } from '../../mock_data';

Vue.use(Vuex);

describe('Author filter', () => {
  let wrapper;
  const mock = new MockAdapter(axios);

  const actions = {
    setQuery: jest.fn(),
    applyQuery: jest.fn(),
  };

  const defaultState = {
    query: {
      scope: 'merge_requests',
      group_id: 1,
      search: '*',
    },
  };

  const createComponent = (state) => {
    const store = new Vuex.Store({
      ...defaultState,
      state,
      actions,
    });

    wrapper = shallowMount(AuthorFilter, {
      store,
    });
  };

  const findFilterDropdown = () => wrapper.findComponent(FilterDropdown);
  const findGlFormCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  beforeEach(() => {
    createComponent();
  });

  describe('when nothing is selected', () => {
    it('renders the component', () => {
      expect(findFilterDropdown().exists()).toBe(true);
      expect(findGlFormCheckbox().exists()).toBe(true);
    });
  });

  describe('when everything is selected', () => {
    beforeEach(() => {
      createComponent({
        query: {
          ...MOCK_QUERY,
          'not[author_username]': 'root',
        },
      });
    });

    it('renders the component with selected options', async () => {
      wrapper.vm.authors = [
        { text: 'Administrator', value: 'root' },
        { text: 'John Doe', value: 'john' },
        { text: 'Jane Doe', value: 'jane' },
      ];

      findFilterDropdown().vm.$emit('selected', 'root');
      await nextTick();

      expect(findFilterDropdown().props('selectedItem')).toBe('root');
    });

    it('displays the correct placeholder text and icon', async () => {
      wrapper.vm.authors = [
        { text: 'Administrator', value: 'root' },
        { text: 'John Doe', value: 'john' },
        { text: 'Jane Doe', value: 'jane' },
      ];
      findFilterDropdown().vm.$emit('selected', 'root');
      await nextTick();
      expect(findFilterDropdown().props('searchText')).toBe('Administrator');
      expect(findFilterDropdown().props('icon')).toBe('user');
    });
  });

  describe('when opening dropdown', () => {
    beforeEach(() => {
      jest.spyOn(axios, 'get');
      jest.spyOn(AjaxCache, 'retrieve');

      createComponent({
        groupInitialJson: {
          id: 1,
          full_name: 'gitlab-org/gitlab-test',
          full_path: 'gitlab-org/gitlab-test',
        },
      });
    });

    afterEach(() => {
      mock.restore();
    });

    it('calls AjaxCache with correct params', () => {
      findFilterDropdown().vm.$emit('shown');
      expect(AjaxCache.retrieve).toHaveBeenCalledWith(
        '/-/autocomplete/users.json?current_user=true&active=true&group_id=1&search=',
      );
    });
  });

  describe.each`
    calledParam          | resetParams               | toggle
    ${'author_username'} | ${'not[author_username]'} | ${false}
    ${'author_username'} | ${'not[author_username]'} | ${true}
  `(
    'when selecting a branch with and withouth toggle $calledParam',
    ({ calledParam, resetParams, toggle }) => {
      beforeEach(() => {
        createComponent({
          query: {
            ...MOCK_QUERY,
          },
        });
      });

      it(`calls setQuery with correct param ${calledParam}`, () => {
        findFilterDropdown().vm.$emit('selected', 'root');
        wrapper.vm.toggleState = !toggle;

        expect(actions.setQuery).toHaveBeenCalledTimes(2);
        expect(actions.setQuery.mock.calls).toMatchObject([
          [
            expect.anything(),
            {
              key: calledParam,
              value: 'root',
            },
          ],
          [
            expect.anything(),
            {
              key: resetParams,
              value: '',
            },
          ],
        ]);
      });
    },
  );

  describe('when reseting selected branch', () => {
    beforeEach(() => {
      createComponent();
    });

    it(`calls setQuery with correct param`, () => {
      findFilterDropdown().vm.$emit('reset');

      expect(actions.setQuery).toHaveBeenCalledWith(expect.anything(), {
        key: 'author_username',
        value: '',
      });

      expect(actions.setQuery).toHaveBeenCalledWith(expect.anything(), {
        key: 'not[author_username]',
        value: '',
      });

      expect(actions.applyQuery).toHaveBeenCalled();
    });
  });
});
