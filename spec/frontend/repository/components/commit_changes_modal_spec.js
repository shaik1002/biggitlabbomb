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
import CommitChangesModal from '~/repository/components/commit_changes_modal.vue';
import { sprintf } from '~/locale';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

const initialProps = {
  modalId: 'Delete-blob',
  action: 'delete',
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
    ({ props, slots } = {}) => {
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
        slots,
      });
    };

  const createComponent = createComponentFactory(shallowMountExtended);
  const createFullComponent = createComponentFactory(mount);

  const findModal = () => wrapper.findComponent(GlModal);
  const findSlot = () => wrapper.findByTestId('test-slot');
  const findForm = () => findModal().findComponent(GlForm);
  const findCommitTextarea = () => findForm().findComponent(GlFormTextarea);
  const findFormRadioGroup = () => findForm().findComponent(GlFormRadioGroup);
  const findRadioGroup = () => findForm().findAllComponents(GlFormRadio);
  const findCurrentBranchRadioOption = () => findRadioGroup().at(0);
  const findNewBranchRadioOption = () => findRadioGroup().at(1);
  const findCreateMrCheckbox = () => findForm().findComponent(GlFormCheckbox);
  const findTargetInput = () => findForm().findComponent(GlFormInput);
  const findCommitHint = () => wrapper.find('[data-testid="hint"]');
  const findBranchInForkMessage = () =>
    wrapper.findByText('GitLab will create a branch in your fork and start a merge request.');

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

    beforeEach(() => createComponent({ props: { isUsingLfs: true } }));

    it('renders a modal containing LFS text', () => {
      expect(findModal().props('title')).toBe(lfsTitleText);
      expect(findModal().text()).toContain(primaryLfsText);
      expect(findModal().text()).toContain(secondaryLfsText);
    });

    it('hides the LFS content if the continue button is clicked', async () => {
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await nextTick();

      expect(findModal().props('title')).not.toBe(lfsTitleText);
      expect(findModal().text()).not.toContain(primaryLfsText);
      expect(findModal().text()).not.toContain(secondaryLfsText);
    });
  });

  describe('renders modal component', () => {
    it('renders with correct props', () => {
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
      expect(findSlot().exists()).toBe(false);
    });

    it('renders the slot when a slot is provided', () => {
      createComponent({
        slots: {
          default: '<div data-testid="test-slot">test slot</div>',
        },
      });
      expect(findSlot().text()).toBe('test slot');
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
      createComponent({ props: { canPushToBranch: false, canPushCode: true } });
      expect(wrapper.vm.$data.form.fields.branch_name.value).toBe('some-target-branch');
      expect(findCommitTextarea().exists()).toBe(true);
      expect(findRadioGroup().exists()).toBe(false);
      expect(findTargetInput().exists()).toBe(true);
      expect(findCreateMrCheckbox().text()).toBe('Create a merge request for this change');
    });

    describe('when `canPushToCode` is `false`', () => {
      const commitInBranchMessage = sprintf(
        'Your changes can be committed to %{branchName} because a merge request is open.',
        {
          branchName: 'main',
        },
      );

      it('shows the correct form fields when `branchAllowsCollaboration` is `true`', () => {
        createComponent({ props: { canPushCode: false, branchAllowsCollaboration: true } });
        expect(findCommitTextarea().exists()).toBe(true);
        expect(findRadioGroup().exists()).toBe(false);
        expect(findModal().text()).toContain(commitInBranchMessage);
        expect(findBranchInForkMessage().exists()).toBe(false);
      });

      it('shows the correct form fields when `branchAllowsCollaboration` is `false`', () => {
        createComponent({
          props: {
            canPushCode: false,
            branchAllowsCollaboration: false,
          },
        });
        expect(findCommitTextarea().exists()).toBe(true);
        expect(findRadioGroup().exists()).toBe(false);
        expect(findModal().text()).not.toContain(commitInBranchMessage);
        expect(findBranchInForkMessage().exists()).toBe(true);
      });
    });

    it('clear branch name when new branch option is selected', async () => {
      createComponent();
      expect(wrapper.vm.$data.form.fields.branch_name).toEqual({
        feedback: null,
        required: true,
        state: true,
        value: 'some-target-branch',
      });

      findFormRadioGroup().vm.$emit('input', true);
      await nextTick();

      expect(wrapper.vm.$data.form.fields.branch_name).toEqual({
        feedback: null,
        required: true,
        state: true,
        value: '',
      });
    });

    it.each`
      input                     | value                          | emptyRepo | canPushCode | canPushToBranch | exist
      ${'authenticity_token'}   | ${'mock-csrf-token'}           | ${false}  | ${true}     | ${true}         | ${true}
      ${'authenticity_token'}   | ${'mock-csrf-token'}           | ${true}   | ${false}    | ${true}         | ${true}
      ${'_method'}              | ${'delete'}                    | ${false}  | ${true}     | ${true}         | ${true}
      ${'_method'}              | ${'delete'}                    | ${true}   | ${false}    | ${true}         | ${true}
      ${'original_branch'}      | ${initialProps.originalBranch} | ${false}  | ${true}     | ${true}         | ${true}
      ${'original_branch'}      | ${undefined}                   | ${true}   | ${true}     | ${true}         | ${false}
      ${'create_merge_request'} | ${'1'}                         | ${false}  | ${false}    | ${true}         | ${true}
      ${'create_merge_request'} | ${'1'}                         | ${false}  | ${true}     | ${true}         | ${true}
      ${'create_merge_request'} | ${'1'}                         | ${false}  | ${false}    | ${false}        | ${true}
      ${'create_merge_request'} | ${'1'}                         | ${false}  | ${false}    | ${true}         | ${true}
      ${'create_merge_request'} | ${undefined}                   | ${true}   | ${false}    | ${true}         | ${false}
    `(
      'passes $input as a hidden input with the correct value',
      ({ input, value, emptyRepo, canPushCode, canPushToBranch, exist }) => {
        createComponent({
          props: {
            emptyRepo,
            canPushCode,
            canPushToBranch,
          },
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
