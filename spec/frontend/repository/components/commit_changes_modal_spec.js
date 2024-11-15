import {
  GlFormTextarea,
  GlModal,
  GlFormCheckbox,
  GlFormInput,
  GlFormRadioGroup,
  GlForm,
  GlSprintf,
  GlFormRadio,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { RENDER_ALL_SLOTS_TEMPLATE, stubComponent } from 'helpers/stub_component';
import setWindowLocation from 'helpers/set_window_location_helper';
import CommitChangesModal from '~/repository/components/commit_changes_modal.vue';
import { sprintf } from '~/locale';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

const initialProps = {
  modalId: 'Delete-blob',
  actionPath: 'some/path',
  commitMessage: 'Delete File',
  targetBranch: 'some-target-branch',
  originalBranch: 'main',
  canPushCode: true,
  canPushToBranch: true,
  emptyRepo: false,
};

const { i18n } = CommitChangesModal;

describe('CommitChangesModal', () => {
  let wrapper;

  const createComponentFactory =
    (mountFn) =>
    (props = {}) => {
      wrapper = mountFn(CommitChangesModal, {
        propsData: {
          ...initialProps,
          ...props,
        },
        attrs: {
          static: true,
          visible: true,
        },
        stubs: {
          GlSprintf,
          GlModal: stubComponent(GlModal, { template: RENDER_ALL_SLOTS_TEMPLATE }),
        },
      });
    };

  const createComponent = createComponentFactory(shallowMountExtended);
  const createFullComponent = createComponentFactory(mount);

  const findModal = () => wrapper.findComponent(GlModal);
  const findForm = () => findModal().findComponent(GlForm);
  const findCommitTextarea = () => findForm().findComponent(GlFormTextarea);
  const findFormRadioGroup = () => findForm().findComponent(GlFormRadioGroup);
  const findRadioGroup = () => findForm().findAllComponents(GlFormRadio);
  const findCurrentBranchRadioOption = () => findRadioGroup().at(0);
  const findNewBranchRadioOption = () => findRadioGroup().at(1);
  const findCreateMrCheckbox = () => findForm().findComponent(GlFormCheckbox);
  const findTargetInput = () => findForm().findComponent(GlFormInput);
  const findCommitHint = () => wrapper.find('[data-testid="hint"]');

  const fillForm = async (inputValue = {}) => {
    const { targetText, commitText } = inputValue;

    await findTargetInput().vm.$emit('input', targetText);
    await findCommitTextarea().vm.$emit('input', commitText);
  };

  describe('LFS files', () => {
    const lfsTitleText = i18n.LFS_WARNING_TITLE;
    const primaryLfsText = sprintf(i18n.LFS_WARNING_PRIMARY_CONTENT, {
      branch: initialProps.targetBranch,
    });

    const secondaryLfsText = sprintf(i18n.LFS_WARNING_SECONDARY_CONTENT, {
      linkStart: '',
      linkEnd: '',
    });

    describe('when deleting a file', () => {
      beforeEach(() => createComponent({ isUsingLfs: true }));

      it('renders a modal containing LFS text', () => {
        expect(findModal().props('title')).toBe(lfsTitleText);
        expect(findModal().text()).toContain(primaryLfsText);
        expect(findModal().text()).toContain(secondaryLfsText);
      });

      it('hides the LFS content when the continue button is clicked', async () => {
        findModal().vm.$emit('primary', { preventDefault: jest.fn() });
        await nextTick();

        expect(findModal().props('title')).not.toBe(lfsTitleText);
        expect(findModal().text()).not.toContain(primaryLfsText);
        expect(findModal().text()).not.toContain(secondaryLfsText);
      });
    });

    describe('when editing a file', () => {
      beforeEach(() => createComponent({ isUsingLfs: true, isEdit: true }));

      it('does not render LFS text', () => {
        expect(findModal().props('title')).not.toBe(lfsTitleText);
        expect(findModal().text()).not.toContain(primaryLfsText);
        expect(findModal().text()).not.toContain(secondaryLfsText);
      });
    });
  });

  it('renders Modal component', () => {
    createComponent();

    expect(findModal().props()).toMatchObject({
      size: 'md',
      actionPrimary: {
        text: 'Commit changes',
      },
      actionCancel: {
        text: 'Cancel',
      },
    });
  });

  describe('form', () => {
    it('gets passed the path for action attribute', () => {
      createComponent();
      expect(findForm().attributes('action')).toBe(initialProps.actionPath);
    });

    it('shows the correct form fields when commit to current branch', () => {
      createComponent();
      expect(findCommitTextarea().exists()).toBe(true);
      expect(findRadioGroup()).toHaveLength(2);
      expect(findCurrentBranchRadioOption().text()).toContain(initialProps.originalBranch);
      expect(findNewBranchRadioOption().text()).toBe('Commit to a new branch');
    });

    it('shows the correct form fields when commit to new branch', async () => {
      createComponent();
      expect(findTargetInput().exists()).toBe(false);

      findFormRadioGroup().vm.$emit('input', true);
      await nextTick();

      expect(findTargetInput().exists()).toBe(true);
      expect(findCreateMrCheckbox().text()).toBe('Create a merge request for this change');
    });

    it('shows the correct form fields when `canPushToBranch` is `false`', () => {
      createComponent({ canPushToBranch: false, canPushCode: true });
      expect(wrapper.vm.$data.form.fields.branch_name.value).toBe('some-target-branch');
      expect(findCommitTextarea().exists()).toBe(true);
      expect(findRadioGroup().exists()).toBe(false);
      expect(findTargetInput().exists()).toBe(true);
      expect(findCreateMrCheckbox().text()).toBe('Create a merge request for this change');
    });

    it.each`
      input                       | value                                         | emptyRepo | canPushCode | canPushToBranch | method      | fileContent           | filePath        | lastCommitSha                                 | fromMergeRequestIid | isEdit   | exist
      ${'authenticity_token'}     | ${'mock-csrf-token'}                          | ${false}  | ${true}     | ${true}         | ${'delete'} | ${''}                 | ${''}           | ${''}                                         | ${''}               | ${false} | ${true}
      ${'authenticity_token'}     | ${'mock-csrf-token'}                          | ${true}   | ${false}    | ${true}         | ${'delete'} | ${''}                 | ${''}           | ${''}                                         | ${''}               | ${false} | ${true}
      ${'_method'}                | ${'delete'}                                   | ${false}  | ${true}     | ${true}         | ${'delete'} | ${''}                 | ${''}           | ${''}                                         | ${''}               | ${false} | ${true}
      ${'_method'}                | ${'delete'}                                   | ${true}   | ${false}    | ${true}         | ${'delete'} | ${''}                 | ${''}           | ${''}                                         | ${''}               | ${false} | ${true}
      ${'_method'}                | ${'put'}                                      | ${false}  | ${true}     | ${true}         | ${'put'}    | ${''}                 | ${''}           | ${''}                                         | ${''}               | ${false} | ${true}
      ${'_method'}                | ${'put'}                                      | ${true}   | ${false}    | ${true}         | ${'put'}    | ${''}                 | ${''}           | ${''}                                         | ${''}               | ${false} | ${true}
      ${'original_branch'}        | ${initialProps.originalBranch}                | ${false}  | ${true}     | ${true}         | ${'delete'} | ${''}                 | ${''}           | ${''}                                         | ${''}               | ${false} | ${true}
      ${'original_branch'}        | ${undefined}                                  | ${true}   | ${true}     | ${true}         | ${'delete'} | ${''}                 | ${''}           | ${''}                                         | ${''}               | ${false} | ${false}
      ${'create_merge_request'}   | ${'1'}                                        | ${false}  | ${false}    | ${true}         | ${'delete'} | ${''}                 | ${''}           | ${''}                                         | ${''}               | ${false} | ${true}
      ${'create_merge_request'}   | ${'1'}                                        | ${false}  | ${true}     | ${true}         | ${'delete'} | ${''}                 | ${''}           | ${''}                                         | ${''}               | ${false} | ${true}
      ${'create_merge_request'}   | ${'1'}                                        | ${false}  | ${false}    | ${false}        | ${'delete'} | ${''}                 | ${''}           | ${''}                                         | ${''}               | ${false} | ${true}
      ${'create_merge_request'}   | ${'1'}                                        | ${false}  | ${false}    | ${true}         | ${'delete'} | ${''}                 | ${''}           | ${''}                                         | ${''}               | ${false} | ${true}
      ${'create_merge_request'}   | ${undefined}                                  | ${true}   | ${false}    | ${true}         | ${'delete'} | ${''}                 | ${''}           | ${''}                                         | ${''}               | ${false} | ${false}
      ${'content'}                | ${'some new content'}                         | ${false}  | ${false}    | ${true}         | ${'put'}    | ${'some new content'} | ${'.gitignore'} | ${''}                                         | ${''}               | ${false} | ${false}
      ${'file_path'}              | ${'.gitignore'}                               | ${false}  | ${false}    | ${true}         | ${'put'}    | ${'some new content'} | ${'.gitignore'} | ${''}                                         | ${''}               | ${false} | ${false}
      ${'file_path'}              | ${'.gitignore'}                               | ${false}  | ${false}    | ${true}         | ${'put'}    | ${'some new content'} | ${'.gitignore'} | ${''}                                         | ${''}               | ${true}  | ${true}
      ${'last_commit_sha'}        | ${'782426692977b2cedb4452ee6501a404410f9b00'} | ${false}  | ${false}    | ${true}         | ${'put'}    | ${''}                 | ${''}           | ${'782426692977b2cedb4452ee6501a404410f9b00'} | ${''}               | ${false} | ${false}
      ${'last_commit_sha'}        | ${'782426692977b2cedb4452ee6501a404410f9b00'} | ${false}  | ${false}    | ${true}         | ${'put'}    | ${''}                 | ${''}           | ${'782426692977b2cedb4452ee6501a404410f9b00'} | ${''}               | ${true}  | ${true}
      ${'from_merge_request_iid'} | ${'17'}                                       | ${false}  | ${false}    | ${true}         | ${'put'}    | ${''}                 | ${''}           | ${''}                                         | ${'17'}             | ${false} | ${false}
      ${'from_merge_request_iid'} | ${'17'}                                       | ${false}  | ${false}    | ${true}         | ${'put'}    | ${''}                 | ${''}           | ${''}                                         | ${'17'}             | ${true}  | ${true}
    `(
      'passes $input as a hidden input with the correct value',
      ({
        input,
        value,
        emptyRepo,
        canPushCode,
        canPushToBranch,
        exist,
        method,
        fileContent,
        lastCommitSha,
        fromMergeRequestIid,
        isEdit,
        filePath,
      }) => {
        if (fromMergeRequestIid) {
          setWindowLocation(
            `https://gitlab.test/foo?from_merge_request_iid=${fromMergeRequestIid}`,
          );
        }
        createComponent({
          emptyRepo,
          canPushCode,
          canPushToBranch,
          method,
          fileContent,
          lastCommitSha,
          isEdit,
          filePath,
        });

        const inputMethod = findForm().find(`input[name="${input}"]`);

        if (!exist) {
          expect(inputMethod.exists()).toBe(false);
          return;
        }

        expect(inputMethod.attributes('type')).toBe('hidden');
        expect(inputMethod.attributes('value')).toBe(value);
      },
    );
  });

  describe('hint', () => {
    const targetText = 'some target branch';
    const hintText = 'Try to keep the first line under 52 characters and the others under 72.';
    const charsGenerator = (length) => 'lorem'.repeat(length);

    beforeEach(async () => {
      createFullComponent();
      findFormRadioGroup().vm.$emit('input', true);
      await nextTick();
    });

    it.each`
      commitText                        | exist    | desc
      ${charsGenerator(53)}             | ${true}  | ${'first line length > 52'}
      ${`lorem\n${charsGenerator(73)}`} | ${true}  | ${'other line length > 72'}
      ${charsGenerator(52)}             | ${true}  | ${'other line length = 52'}
      ${`lorem\n${charsGenerator(72)}`} | ${true}  | ${'other line length = 72'}
      ${`lorem`}                        | ${false} | ${'first line length < 53'}
      ${`lorem\nlorem`}                 | ${false} | ${'other line length < 53'}
    `('displays hint $exist for $desc', async ({ commitText, exist }) => {
      await fillForm({ targetText, commitText });

      if (!exist) {
        expect(findCommitHint().exists()).toBe(false);
        return;
      }

      expect(findCommitHint().text()).toBe(hintText);
    });
  });

  describe('form submission', () => {
    let submitSpy;

    beforeEach(async () => {
      createFullComponent();
      await nextTick();
      submitSpy = jest.spyOn(findForm().element, 'submit');
    });

    afterEach(() => {
      submitSpy.mockRestore();
    });

    describe('invalid form', () => {
      beforeEach(async () => {
        findFormRadioGroup().vm.$emit('input', true);
        await nextTick();

        await fillForm({ targetText: '', commitText: '' });
      });

      it('disables submit button', () => {
        expect(findModal().props('actionPrimary').attributes).toEqual(
          expect.objectContaining({ disabled: true }),
        );
      });

      it('does not submit form', () => {
        findModal().vm.$emit('primary', { preventDefault: () => {} });
        expect(submitSpy).not.toHaveBeenCalled();
      });
    });

    describe('valid form', () => {
      beforeEach(async () => {
        findFormRadioGroup().vm.$emit('input', true);
        await nextTick();
        await fillForm({
          targetText: 'some valid target branch',
          commitText: 'some valid commit message',
        });
      });

      it('enables submit button', () => {
        expect(findModal().props('actionPrimary').attributes).toEqual(
          expect.objectContaining({ disabled: false }),
        );
      });

      it('submits form', () => {
        findModal().vm.$emit('primary', { preventDefault: () => {} });
        expect(submitSpy).toHaveBeenCalled();
      });
    });
  });
});
