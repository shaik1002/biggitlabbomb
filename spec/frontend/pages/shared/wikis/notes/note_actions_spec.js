import { GlDisclosureDropdownGroup } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NoteActions from '~/pages/shared/wikis/wiki_notes/components/note_actions.vue';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';

describe('WikiNoteActions', () => {
  let wrapper;

  const findDisclosureDropdownGroup = () => wrapper.findComponent(GlDisclosureDropdownGroup);
  const findReportAbuseButton = () => wrapper.findByTestId('wiki-note-report-abuse-button');
  const findEditButton = () => wrapper.findByTestId('wiki-note-edit-button');
  const findReplyButton = () => wrapper.findByTestId('wiki-note-reply-button');
  const findCopyNoteButton = () => wrapper.findByTestId('wiki-note-copy-note');
  const findDeleteButton = () => wrapper.findByTestId('wiki-note-delete-button');

  const createWrapper = (propsData = { authorId: 'gid://gitlab/User/1' }) => {
    return shallowMountExtended(NoteActions, {
      propsData,
    });
  };

  describe('renders correctly', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    describe('note actions', () => {
      it('should not render any actions by default', () => {
        expect(findEditButton().exists()).toBe(false);
        expect(findReportAbuseButton().exists()).toBe(false);
        expect(findDisclosureDropdownGroup().exists()).toBe(false);
      });

      it('should render edit button when showEdit is true', async () => {
        wrapper.setProps({ showEdit: true });
        await nextTick();
        expect(findEditButton().exists()).toBe(true);
      });

      it('should render reply button when showReply is true', async () => {
        wrapper.setProps({ showReply: true });
        await nextTick();
        expect(findReplyButton().exists()).toBe(true);
      });
    });

    describe('actions dropdown group', () => {
      it('should render the dropdown group when canReportAsAbuse is true', async () => {
        wrapper.setProps({ canReportAsAbuse: true });
        await nextTick();
        expect(findDisclosureDropdownGroup().exists()).toBe(true);
      });

      it('should render the dropdown group when showEdit is true', async () => {
        wrapper.setProps({ showEdit: true });
        await nextTick();
        expect(findDisclosureDropdownGroup().exists()).toBe(true);
      });

      it('should render the dropdown group when both canReportAsAbuse and showEdit are true', async () => {
        wrapper.setProps({ canReportAsAbuse: true, showEdit: true });
        await nextTick();
        expect(findDisclosureDropdownGroup().exists()).toBe(true);
      });

      it('should not render the dropdown group when neither canReportAsAbuse nor showEdit is true', async () => {
        wrapper.setProps({ canReportAsAbuse: false, showEdit: false });
        await nextTick();
        expect(findDisclosureDropdownGroup().exists()).toBe(false);
      });
    });

    describe('actions dropdown', () => {
      it('should not render copy link button when noteUrl is empty', async () => {
        wrapper.setProps({ canReportAsAbuse: true });
        await nextTick();
        expect(findCopyNoteButton().exists()).toBe(false);
      });

      it('should render copy link button when noteUrl is provided', async () => {
        wrapper.setProps({ canReportAsAbuse: true, noteUrl: 'example.com' });
        await nextTick();
        expect(findCopyNoteButton().exists()).toBe(true);
      });

      it('should not render delete button when showEdit is false', async () => {
        wrapper.setProps({ canReportAsAbuse: true, showEdit: false });
        await nextTick();
        expect(findDeleteButton().exists()).toBe(false);
      });

      it('should render delete button when showEdit is true', async () => {
        wrapper.setProps({ canReportAsAbuse: true, showEdit: true });
        await nextTick();
        expect(findDeleteButton().exists()).toBe(true);
      });

      it('should not render report as abuse button when canReportAsAbuse is false', async () => {
        wrapper.setProps({ canReportAsAbuse: false, showEdit: true });
        await nextTick();
        expect(findReportAbuseButton().exists()).toBe(false);
      });

      it('should render report as abuse button when canReportAsAbuse is true', async () => {
        wrapper.setProps({ canReportAsAbuse: true });
        await nextTick();
        expect(findReportAbuseButton().exists()).toBe(true);
      });
    });
  });

  describe('actions function correctly', () => {
    beforeEach(async () => {
      wrapper = createWrapper({
        authorId: '1',
        showReply: true,
        showEdit: true,
        canReportAsAbuse: true,
      });
      await nextTick();
    });

    describe('note actions', () => {
      it('emits reply event when reply is clicked', () => {
        findReplyButton().vm.$emit('click');
        expect(Boolean(wrapper.emitted('reply'))).toBe(true);
      });

      it('emits edit event when edit is clicked', () => {
        findEditButton().vm.$emit('click');
        expect(Boolean(wrapper.emitted('edit'))).toBe(true);
      });
    });

    describe('actions dropdown', () => {
      const findAbuseCategorySelector = () => wrapper.findComponent(AbuseCategorySelector);

      it('emits delete event when the delete button is clicked', () => {
        findDeleteButton().vm.$emit('action');
        expect(Boolean(wrapper.emitted('delete'))).toBe(true);
      });

      it('shows report as abuse drawer when report as abuse', async () => {
        await findReportAbuseButton().vm.$emit('action');

        expect(findAbuseCategorySelector().props('showDrawer')).toEqual(true);
      });

      it('closes report as abuse drawer when it emits the close-drawer event', async () => {
        await findReportAbuseButton().vm.$emit('action');
        findAbuseCategorySelector().vm.$emit('close-drawer');

        await nextTick();

        expect(findAbuseCategorySelector().exists()).toEqual(false);
      });
    });
  });
});
