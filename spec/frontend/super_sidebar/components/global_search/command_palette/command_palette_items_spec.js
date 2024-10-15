import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { GlDisclosureDropdownGroup, GlDisclosureDropdownItem, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import CommandPaletteItems from '~/super_sidebar/components/global_search/command_palette/command_palette_items.vue';
import {
  COMMAND_HANDLE,
  USERS_GROUP_TITLE,
  PATH_GROUP_TITLE,
  USER_HANDLE,
  PATH_HANDLE,
  PROJECT_HANDLE,
  SEARCH_SCOPE,
  MAX_ROWS,
} from '~/super_sidebar/components/global_search/command_palette/constants';
import {
  commandMapper,
  linksReducer,
  fileMapper,
} from '~/super_sidebar/components/global_search/command_palette/utils';
import { getFormattedItem } from '~/super_sidebar/components/global_search/utils';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { mockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { COMMANDS, LINKS, USERS, FILES } from './mock_data';

const links = LINKS.reduce(linksReducer, []);

describe('CommandPaletteItems', () => {
  let wrapper;
  const autocompletePath = '/autocomplete';
  const searchContext = { project: { id: 1 }, group: { id: 2 } };
  const projectFilesPath = 'project/files/path';
  const projectBlobPath = '/blob/main';

  const createComponent = (props, options = {}) => {
    wrapper = shallowMount(CommandPaletteItems, {
      propsData: {
        handle: COMMAND_HANDLE,
        searchQuery: '',
        ...props,
      },
      stubs: {
        GlDisclosureDropdownGroup,
        GlDisclosureDropdownItem,
      },
      provide: {
        commandPaletteCommands: COMMANDS,
        commandPaletteLinks: LINKS,
        autocompletePath,
        searchContext,
        projectFilesPath,
        projectBlobPath,
      },
      ...options,
    });
  };

  const findItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findGroups = () => wrapper.findAllComponents(GlDisclosureDropdownGroup);
  const findLoader = () => wrapper.findComponent(GlLoadingIcon);

  describe('Commands and links', () => {
    it('renders all commands initially', () => {
      createComponent();
      const commandGroup = COMMANDS.map(commandMapper)[0];
      expect(findItems()).toHaveLength(commandGroup.items.length);
      expect(findGroups().at(0).props('group')).toEqual({
        name: commandGroup.name,
        items: commandGroup.items,
      });
    });

    describe('with search query', () => {
      it('should filter commands and links by the search query', async () => {
        jest.spyOn(fuzzaldrinPlus, 'filter');
        createComponent({ searchQuery: 'mr' });
        const searchQuery = 'todo';
        await wrapper.setProps({ searchQuery });
        const commandGroup = COMMANDS.map(commandMapper)[0];
        expect(fuzzaldrinPlus.filter).toHaveBeenCalledWith(
          commandGroup.items,
          searchQuery,
          expect.objectContaining({ key: 'text' }),
        );
        expect(fuzzaldrinPlus.filter).toHaveBeenCalledWith(
          links,
          searchQuery,
          expect.objectContaining({ key: 'keywords' }),
        );
      });

      it('should display no results message when no command matched the search query', async () => {
        jest.spyOn(fuzzaldrinPlus, 'filter').mockReturnValue([]);
        createComponent({ searchQuery: 'mr' });
        const searchQuery = 'todo';
        await wrapper.setProps({ searchQuery });
        expect(wrapper.text()).toBe('No results found');
      });
    });
  });

  describe('Users, issues, and projects', () => {
    let mockAxios;

    beforeEach(() => {
      mockAxios = new MockAdapter(axios);
    });

    it('should NOT start search by the search query which is less than 3 chars', () => {
      jest.spyOn(axios, 'get');
      const searchQuery = 'us';
      createComponent({ handle: USER_HANDLE, searchQuery });

      expect(axios.get).not.toHaveBeenCalled();

      expect(findLoader().exists()).toBe(false);
    });

    it('should start scoped search with 3+ chars and display a loader', () => {
      jest.spyOn(axios, 'get');
      const searchQuery = 'user';
      createComponent({ handle: USER_HANDLE, searchQuery });

      expect(axios.get).toHaveBeenCalledWith(
        `${autocompletePath}?term=${searchQuery}&project_id=${searchContext.project.id}&filter=search&scope=${SEARCH_SCOPE[USER_HANDLE]}`,
      );
      expect(findLoader().exists()).toBe(true);
    });

    it('should render returned items', async () => {
      mockAxios.onGet().replyOnce(HTTP_STATUS_OK, USERS);

      const searchQuery = 'user';
      createComponent({ handle: USER_HANDLE, searchQuery });

      await waitForPromises();
      expect(findItems()).toHaveLength(USERS.length);
      expect(findGroups().at(0).props('group')).toMatchObject({
        name: USERS_GROUP_TITLE,
        items: USERS.map(getFormattedItem),
      });
    });

    it('should display no results message when no users matched the search query', async () => {
      mockAxios.onGet().replyOnce(HTTP_STATUS_OK, []);
      const searchQuery = 'user';
      createComponent({ handle: USER_HANDLE, searchQuery });
      await waitForPromises();
      expect(wrapper.text()).toBe('No results found');
    });
  });

  describe('Project files', () => {
    let mockAxios;

    beforeEach(() => {
      mockAxios = new MockAdapter(axios);
    });

    it('should request project files on first search', () => {
      jest.spyOn(axios, 'get');
      const searchQuery = 'gitlab-ci.yml';
      createComponent({ handle: PATH_HANDLE, searchQuery });

      expect(axios.get).toHaveBeenCalledWith(projectFilesPath);
      expect(findLoader().exists()).toBe(true);
    });

    it(`should render all items when returned number of items is less than ${MAX_ROWS}`, async () => {
      const numberOfItems = MAX_ROWS - 1;
      const items = FILES.slice(0, numberOfItems).map(fileMapper.bind(null, projectBlobPath));
      mockAxios.onGet().replyOnce(HTTP_STATUS_OK, FILES.slice(0, numberOfItems));
      jest.spyOn(fuzzaldrinPlus, 'filter').mockReturnValue(items);

      const searchQuery = 'gitlab-ci.yml';
      createComponent({ handle: PATH_HANDLE, searchQuery });

      await waitForPromises();

      expect(findGroups().at(0).props('group')).toMatchObject({
        name: PATH_GROUP_TITLE,
        items: items.slice(0, MAX_ROWS),
      });

      expect(findItems()).toHaveLength(numberOfItems);
    });

    it(`should render first ${MAX_ROWS} returned items when number of returned items exceeds ${MAX_ROWS}`, async () => {
      const items = FILES.map(fileMapper.bind(null, projectBlobPath));
      mockAxios.onGet().replyOnce(HTTP_STATUS_OK, FILES);
      jest.spyOn(fuzzaldrinPlus, 'filter').mockReturnValue(items);

      const searchQuery = 'gitlab-ci.yml';
      createComponent({ handle: PATH_HANDLE, searchQuery });

      await waitForPromises();

      expect(findItems()).toHaveLength(MAX_ROWS);
      expect(findGroups().at(0).props('group')).toMatchObject({
        name: PATH_GROUP_TITLE,
        items: items.slice(0, MAX_ROWS),
      });
    });

    it('should display no results message when no files matched the search query', async () => {
      mockAxios.onGet().replyOnce(HTTP_STATUS_OK, []);
      const searchQuery = 'gitlab-ci.yml';
      createComponent({ handle: PATH_HANDLE, searchQuery });
      await waitForPromises();
      expect(wrapper.text()).toBe('No results found');
    });

    it('should not make additional server call on the search query change', async () => {
      const searchQuery = 'gitlab-ci.yml';
      const newSearchQuery = 'package.json';

      jest.spyOn(axios, 'get');

      createComponent({ handle: PATH_HANDLE, searchQuery });

      mockAxios.onGet().replyOnce(HTTP_STATUS_OK, FILES);
      await waitForPromises();

      expect(axios.get).toHaveBeenCalledTimes(1);

      await wrapper.setProps({ searchQuery: newSearchQuery });

      expect(axios.get).toHaveBeenCalledTimes(1);
    });
  });

  describe('Tracking', () => {
    let trackingSpy;
    let mockAxios;

    beforeEach(() => {
      trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
      mockAxios = new MockAdapter(axios);
      createComponent({ attachTo: document.body });
    });

    afterEach(() => {
      mockAxios.restore();
    });

    it('tracks event immediately', () => {
      expect(trackingSpy).toHaveBeenCalledTimes(1);
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'activate_command_palette', {
        label: 'command',
      });
    });

    it.each`
      handle            | label
      ${USER_HANDLE}    | ${'user'}
      ${PROJECT_HANDLE} | ${'project'}
      ${PATH_HANDLE}    | ${'path'}
    `('tracks changing the handle to "$handle"', async ({ handle, label }) => {
      trackingSpy.mockClear();

      await wrapper.setProps({ handle });
      expect(trackingSpy).toHaveBeenCalledTimes(1);
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'activate_command_palette', {
        label,
      });
    });
  });
});
