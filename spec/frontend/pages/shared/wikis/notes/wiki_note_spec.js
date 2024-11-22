import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WikiNote from '~/pages/shared/wikis/wiki_notes/components/wiki_note.vue';
import { getIdFromGid } from '~/pages/shared/wikis/wiki_notes/utils';
import NoteHeader from '~/pages/shared/wikis/wiki_notes/components/note_header.vue';
import NoteActions from '~/pages/shared/wikis/wiki_notes/components/note_actions.vue';
import NoteBody from '~/pages/shared/wikis/wiki_notes/components/note_body.vue';
import DeleteNoteMutation from '~/wikis/graphql/notes/delete_wiki_page_note.mutation.graphql';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import * as autosave from '~/lib/utils/autosave';
import * as confirmViaGLModal from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import * as alert from '~/alert';
import { noteableType, currentUserData, note, noteableId } from './mock_data';

describe('WikiNote', () => {
  let wrapper;

  const $apollo = {
    mutate: jest.fn(),
  };

  const createWrapper = (props, provideData) => {
    return shallowMountExtended(WikiNote, {
      propsData: {
        note,
        noteableId,
        ...props,
      },
      mocks: {
        $apollo,
      },
      provide: {
        noteableType,
        currentUserData,
        ...provideData,
      },
      stubs: {
        GlAvatarLink: {
          template: '<div><slot></slot></div>',
          props: ['href', 'data-user-id', 'data-username'],
        },
        GlAvatar: {
          template: '<img/>',
          props: ['src', 'entity-name', 'alt'],
        },
      },
    });
  };

  beforeEach(() => {
    wrapper = createWrapper();
  });

  describe('renders correctly by default', () => {
    it('should render time line entry item correctly', () => {
      const timelineEntryItem = wrapper.findComponent(TimelineEntryItem);

      expect(timelineEntryItem.element.classList).not.toContain(
        'gl-opacity-5',
        'gl-ponter-events-none',
        'is-editable',
        'internal-note',
      );
    });

    it('should render author avatar correctly', () => {
      const avatarLink = wrapper.findComponent(GlAvatarLink);

      expect(avatarLink.props()).toMatchObject({
        href: note.author.webPath,
        dataUserId: getIdFromGid(note.author.id),
        dataUsername: 'root',
      });

      const avatar = avatarLink.findComponent(GlAvatar);

      expect(avatar.props()).toMatchObject({
        alt: note.author.name,
        entityName: note.author.username,
        src: note.author.avatarUrl,
      });
    });

    it('renders note header correctly', () => {
      const noteHeader = wrapper.findComponent(NoteHeader);

      expect(noteHeader.props()).toMatchObject({
        author: note.author,
        createdAt: note.createdAt,
      });
    });

    it('renders note actions correctly', () => {
      const noteActions = wrapper.findComponent(NoteActions);

      expect(noteActions.props()).toMatchObject({
        authorId: getIdFromGid(note.author.id),
        noteUrl: note.url,
        showReply: false,
        showEdit: false,
        canReportAsAbuse: true,
      });
    });

    it('renders note body correctly', () => {
      const noteBody = wrapper.findComponent(NoteBody);

      expect(noteBody.props()).toMatchObject({
        note,
        noteableId,
        isEditing: false,
      });
    });

    it('should not render when isDeleted is true', async () => {
      // eslint-disable-next-line no-restricted-syntax
      await wrapper.setData({ isDeleted: true });

      expect(wrapper.findComponent(TimelineEntryItem).exists()).toBe(false);
    });
  });

  describe('when user is signed in', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('should emit reply when reply event is fired from note actions', () => {
      const noteActions = wrapper.findComponent(NoteActions);
      noteActions.vm.$emit('reply');

      expect(Boolean(wrapper.emitted('reply'))).toBe(true);
    });

    it('should pass prop "showReply" as true to note actions when user can reply', async () => {
      await wrapper.setProps({
        userPermissions: {
          createNote: true,
        },
      });

      const noteActions = wrapper.findComponent(NoteActions);
      expect(noteActions.props().showReply).toBe(true);
    });

    it('should pass prop "showReply" as false to note actions when user cannot reply', async () => {
      await wrapper.setProps({
        userPermissions: {
          createNote: false,
        },
      });

      const noteActions = wrapper.findComponent(NoteActions);
      expect(noteActions.props().showReply).toBe(false);
    });

    describe('user cannot edit', () => {
      it('should pass false to showEdit prop of note actions', () => {
        const noteActions = wrapper.findComponent(NoteActions);
        expect(noteActions.props().showEdit).toBe(false);
      });

      it('should pass false to canEdit prop of note body', () => {
        const noteBody = wrapper.findComponent(NoteBody);
        expect(noteBody.props().canEdit).toBe(false);
      });
    });

    describe('user can edit', () => {
      beforeEach(async () => {
        await wrapper.setProps({
          note: {
            ...note,
            author: {
              ...note.author,
              id: convertToGraphQLId(TYPENAME_USER, currentUserData.id),
            },
          },
        });
      });

      it('should pass true to showEdit prop of note actions', () => {
        const noteActions = wrapper.findComponent(NoteActions);
        expect(noteActions.props().showEdit).toBe(true);
      });

      it('should pass true to canEdit prop of note body', () => {
        const noteBody = wrapper.findComponent(NoteBody);
        expect(noteBody.props().canEdit).toBe(true);
      });

      describe('when editing', () => {
        beforeEach(() => {
          wrapper.vm.toggleEditing(true);
        });

        afterEach(() => {
          jest.restoreAllMocks();
        });

        it('isEditing should be true', () => {
          expect(wrapper.vm.isEditing).toBe(true);
        });

        it('should pass isEditing prop as true to the note body', () => {
          const noteBody = wrapper.findComponent(NoteBody);
          expect(noteBody.props().isEditing).toBe(true);
        });

        it('should clear draft when isEditing is set to false', () => {
          const clearDraftSpy = jest.spyOn(autosave, 'clearDraft');
          wrapper.vm.toggleEditing(false);

          expect(clearDraftSpy).toHaveBeenCalled();
        });

        it('should toggle editing to false when cancel:edit event is fired from note body component', () => {
          wrapper.findComponent(NoteBody).vm.$emit('cancel:edit');
          expect(wrapper.vm.isEditing).toBe(false);
        });

        it('should toggle editing to false when creating-note:success event is fired from note body component', () => {
          wrapper.findComponent(NoteBody).vm.$emit('creating-note:success');
          expect(wrapper.vm.isEditing).toBe(false);
        });
      });

      describe('when not editing', () => {
        it('isEditing should be false', () => {
          expect(wrapper.vm.isEditing).toBe(false);
        });

        it('should toggle editing to true when edit event is fired from note actions', () => {
          wrapper.findComponent(NoteActions).vm.$emit('edit');
          expect(wrapper.vm.isEditing).toBe(true);
        });
      });

      describe('when updating', () => {
        beforeEach(() => {
          wrapper.vm.toggleUpdating(true);
        });

        it('should set isUpdating to true', () => {
          expect(wrapper.vm.isUpdating).toBe(true);
        });

        it('should add opacity and disable pointer events on timeline entry item', () => {
          const timelineEntryItem = wrapper.findComponent(TimelineEntryItem);
          expect(timelineEntryItem.element.classList).toContain('gl-opacity-5');
          expect(timelineEntryItem.element.classList).toContain('gl-pointer-events-none');
        });

        it('should show spinner on note header', () => {
          const noteHeader = wrapper.findComponent(NoteHeader);

          expect(noteHeader.props().showSpinner).toBe(true);
        });

        it('should set isUpdating to false when creating-note:done event is fired from note body component', () => {
          wrapper.findComponent(NoteBody).vm.$emit('creating-note:done');
          expect(wrapper.vm.isUpdating).toBe(false);
        });
      });

      describe('when not updating', () => {
        it('isUpdating should be false', () => {
          expect(wrapper.vm.isUpdating).toBe(false);
        });

        it('should set isUpdating to true when creating-note:start event is fired from note body component', () => {
          wrapper.findComponent(NoteBody).vm.$emit('creating-note:start');
          expect(wrapper.vm.isUpdating).toBe(true);
        });

        it('shoould not show spinner on note header', () => {
          const noteHeader = wrapper.findComponent(NoteHeader);
          expect(noteHeader.props().showSpinner).toBe(false);
        });

        it('should remove opacity and disable pointer events on timeline entry item', () => {
          const timelineEntryItem = wrapper.findComponent(TimelineEntryItem);
          expect(timelineEntryItem.element.classList).not.toContain('gl-opacity-5');
          expect(timelineEntryItem.element.classList).not.toContain('gl-pointer-events-none');
        });
      });

      describe('when deleting', () => {
        it('should add opacity and disable pointer events on timeline entry item', async () => {
          // eslint-disable-next-line no-restricted-syntax
          await wrapper.setData({
            isDeleting: true,
          });

          const timelineEntryItem = wrapper.findComponent(TimelineEntryItem);
          expect(timelineEntryItem.element.classList).toContain('gl-opacity-5');
          expect(timelineEntryItem.element.classList).toContain('gl-pointer-events-none');
        });

        describe('deleteNote', () => {
          beforeEach(() => {
            $apollo.mutate.mockClear();
          });

          afterEach(() => {
            jest.restoreAllMocks();
          });

          it('should confirm with user before deleting', () => {
            const confirmSpy = jest.spyOn(confirmViaGLModal, 'confirmAction');
            wrapper.vm.deleteNote();

            expect(confirmSpy).toHaveBeenCalledWith(
              'Are you sure you want to delete this comment?',
              {
                primaryBtnVariant: 'danger',
                primaryBtnText: 'Delete comment',
              },
            );
          });

          it('should not attempt to delete note if user does not confirm delete note action', () => {
            jest.spyOn(confirmViaGLModal, 'confirmAction').mockImplementation(() => false);

            wrapper.vm.deleteNote();
            expect($apollo.mutate).not.toHaveBeenCalled();
          });

          it('should attempt to delete note if user confirms delete note action', async () => {
            jest.spyOn(confirmViaGLModal, 'confirmAction').mockImplementation(() => true);

            await wrapper.vm.deleteNote();
            expect($apollo.mutate).toHaveBeenCalledWith({
              mutation: DeleteNoteMutation,
              variables: {
                input: {
                  id: note.id,
                },
              },
            });
          });

          it('should handle error appropriately when delete note is not successful', async () => {
            jest.spyOn(confirmViaGLModal, 'confirmAction').mockImplementation(() => true);

            const createAlertSpy = jest.spyOn(alert, 'createAlert');

            $apollo.mutate.mockRejectedValue();

            await wrapper.vm.deleteNote();

            expect(wrapper.vm.isDeleted).toBe(false);
            expect(createAlertSpy).toHaveBeenCalledWith({
              message: 'Something went wrong while deleting your note. Please try again.',
            });
            expect(wrapper.vm.isDeleting).toBe(false);
          });

          it('should set deleted to true when delete note is successful', async () => {
            jest.spyOn(confirmViaGLModal, 'confirmAction').mockImplementation(() => true);

            $apollo.mutate.mockResolvedValue();

            await wrapper.vm.deleteNote();
            expect(wrapper.vm.isDeleted).toBe(true);
          });
        });
      });

      describe('when not deleting', () => {
        it('isDeleting should be false', () => {
          expect(wrapper.vm.isDeleting).toBe(false);
        });

        it('should remove opacity and disable pointer events on timeline entry item', () => {
          const timelineEntryItem = wrapper.findComponent(TimelineEntryItem);
          expect(timelineEntryItem.element.classList).not.toContain('gl-opacity-5');
          expect(timelineEntryItem.element.classList).not.toContain('gl-pointer-events-none');
        });
      });
    });
  });
});
