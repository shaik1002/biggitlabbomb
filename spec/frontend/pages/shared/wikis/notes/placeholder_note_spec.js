import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
import PlaceholderNote from '~/pages/shared/wikis/wiki_notes/components/placeholder_note.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import { currentUserData, note } from './mock_data';

describe('PlaceholderNote', () => {
  let wrapper;

  const createWrapper = (props, provideData = { currentUserData }) =>
    shallowMountExtended(PlaceholderNote, {
      propsData: {
        note,
        ...props,
      },
      provide: provideData,
      stubs: {
        TimelineEntryItem,
      },
    });

  describe('renders correctly', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('should evaluate dynamic styles correctly when replyNote is true', () => {
      wrapper = createWrapper({ replyNote: true });
      const { dynamicClasses } = wrapper.vm;

      expect(dynamicClasses).toStrictEqual({
        internalNote: {
          'internal-note': false,
        },
        noteParent: {
          card: false,
          'gl-ml-7': true,
          'gl-ml-8': false,
        },
      });
    });

    it('should evaluate dynamic styles correctly when replyNote is false', () => {
      const { dynamicClasses } = wrapper.vm;

      expect(dynamicClasses).toStrictEqual({
        internalNote: {
          'internal-note': false,
        },
        noteParent: {
          card: true,
          'gl-ml-7': false,
          'gl-ml-8': true,
        },
      });
    });

    it('should render user avatar with link to current user path when set', () => {
      const avatarLink = wrapper.findComponent(GlAvatarLink);
      expect(avatarLink.attributes('href')).toBe(currentUserData.path);
    });

    it('user avatar ref should default to web url when current user path is not set', () => {
      wrapper = createWrapper(
        {},
        {
          currentUserData: {
            ...currentUserData,
            path: null,
          },
        },
      );
      const avatarLink = wrapper.findComponent(GlAvatarLink);
      expect(avatarLink.attributes('href')).toBe(currentUserData.web_url);
    });

    describe('user avatar', () => {
      let avatarLink;
      let avatar;

      beforeEach(() => {
        avatarLink = wrapper.findComponent(GlAvatarLink);
        avatar = avatarLink.findComponent(GlAvatar);
      });

      it('should set the src correctly', () => {
        expect(avatar.attributes('src')).toBe(currentUserData.avatar_url);
      });

      it('should set the alt correctly', () => {
        expect(avatar.attributes('alt')).toBe(currentUserData.name);
      });
    });

    describe('note header', () => {
      let noteHeader;

      beforeEach(() => {
        noteHeader = wrapper.findByTestId('wiki-placeholder-note-header');
      });

      it('should render user link with href to current user path when set', () => {
        const userLink = noteHeader.find('a');
        expect(userLink.attributes('href')).toBe(currentUserData.path);
      });

      it('user link href should default to web url when current user path is not set', () => {
        wrapper = createWrapper(
          {},
          {
            currentUserData: {
              ...currentUserData,
              path: null,
            },
          },
        );
        const userLink = noteHeader.find('a');
        expect(userLink.attributes('href')).toBe(currentUserData.web_url);
      });

      it('should render note header text correctly', async () => {
        const userName = await noteHeader.text();
        expect(userName).toBe(`${currentUserData.name} @${currentUserData.username}`);
      });
    });

    it('should rander note body text correctly', async () => {
      const noteBody = await wrapper
        .findByTestId('wiki-placeholder-note-body')
        .find('.note-text')
        .text();

      expect(noteBody).toBe(note.body);
    });
  });
});
