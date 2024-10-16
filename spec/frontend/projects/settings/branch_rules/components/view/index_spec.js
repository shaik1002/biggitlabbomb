import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal, GlCard, GlCollapsibleListbox, GlToast } from '@gitlab/ui';
import { sprintf } from '~/locale';
import * as util from '~/lib/utils/url_utility';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/alert';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import RuleView from '~/projects/settings/branch_rules/components/view/index.vue';
import RuleDrawer from '~/projects/settings/branch_rules/components/view/rule_drawer.vue';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import Protection from '~/projects/settings/branch_rules/components/view/protection.vue';
import ProtectionToggle from '~/projects/settings/branch_rules/components/view/protection_toggle.vue';
import BranchRuleModal from '~/projects/settings/components/branch_rule_modal.vue';
import getProtectableBranches from '~/projects/settings/graphql/queries/protectable_branches.query.graphql';

import {
  I18N,
  ALL_BRANCHES_WILDCARD,
  DELETE_RULE_MODAL_ID,
  EDIT_RULE_MODAL_ID,
} from '~/projects/settings/branch_rules/components/view/constants';
import branchRulesQuery from 'ee_else_ce/projects/settings/branch_rules/queries/branch_rules_details.query.graphql';
import deleteBranchRuleMutation from '~/projects/settings/branch_rules/mutations/branch_rule_delete.mutation.graphql';
import editBranchRuleMutation from 'ee_else_ce/projects/settings/branch_rules/mutations/edit_branch_rule.mutation.graphql';
import {
  editBranchRuleMockResponse,
  deleteBranchRuleMockResponse,
  branchProtectionsMockResponse,
  branchProtectionsNoPushAccessMockResponse,
  predefinedBranchRulesMockResponse,
  matchingBranchesCount,
  protectableBranchesMockResponse,
  allowedToMergeDrawerProps,
  protectionMockProps,
} from 'ee_else_ce_jest/projects/settings/branch_rules/components/view/mock_data';

jest.mock('~/lib/utils/url_utility', () => ({
  getParameterByName: jest.fn().mockReturnValue('main'),
  mergeUrlParams: jest.fn().mockReturnValue('/branches?state=all&search=%5Emain%24'),
  joinPaths: jest.fn(),
  setUrlParams: jest
    .fn()
    .mockReturnValue('/project/Project/-/settings/repository/branch_rules?branch=main'),
  visitUrl: jest.fn().mockName('visitUrlMock'),
}));

jest.mock('~/alert');

Vue.use(VueApollo);
Vue.use(GlToast);
useMockLocationHelper();

describe('View branch rules', () => {
  let wrapper;
  let fakeApollo;
  const projectPath = 'test/testing';
  const protectedBranchesPath = 'protected/branches';
  const branchRulesPath = '/-/settings/repository#branch_rules';
  const branchRulesMockRequestHandler = jest.fn().mockResolvedValue(branchProtectionsMockResponse);
  const predefinedBranchRulesMockRequestHandler = jest
    .fn()
    .mockResolvedValue(predefinedBranchRulesMockResponse);
  const deleteBranchRuleSuccessHandler = jest.fn().mockResolvedValue(deleteBranchRuleMockResponse);
  const editBranchRuleSuccessHandler = jest.fn().mockResolvedValue(editBranchRuleMockResponse);
  const protectableBranchesMockRequestHandler = jest
    .fn()
    .mockResolvedValue(protectableBranchesMockResponse);
  const errorHandler = jest.fn().mockRejectedValue('error');
  const showToast = jest.fn();

  const createComponent = async ({
    glFeatures = { editBranchRules: true },
    branchRulesQueryHandler = branchRulesMockRequestHandler,
    deleteMutationHandler = deleteBranchRuleSuccessHandler,
    editMutationHandler = editBranchRuleSuccessHandler,
  } = {}) => {
    fakeApollo = createMockApollo([
      [branchRulesQuery, branchRulesQueryHandler],
      [getProtectableBranches, protectableBranchesMockRequestHandler],
      [deleteBranchRuleMutation, deleteMutationHandler],
      [editBranchRuleMutation, editMutationHandler],
    ]);

    wrapper = shallowMountExtended(RuleView, {
      apolloProvider: fakeApollo,
      provide: {
        projectPath,
        protectedBranchesPath,
        branchRulesPath,
        glFeatures,
      },
      stubs: {
        Protection,
        ProtectionToggle,
        BranchRuleModal,
        RuleDrawer,
        GlCard: stubComponent(GlCard, { template: RENDER_ALL_SLOTS_TEMPLATE }),
        GlModal: stubComponent(GlModal, { template: RENDER_ALL_SLOTS_TEMPLATE }),
      },
      mocks: {
        $toast: {
          show: showToast,
        },
      },
      directives: { GlModal: createMockDirective('gl-modal') },
    });

    await waitForPromises();
  };

  beforeEach(() => createComponent());

  afterEach(() => {
    fakeApollo = null;
    showToast.mockReset();
  });

  const findBranchName = () => wrapper.findByTestId('branch');
  const findAllBranches = () => wrapper.findByTestId('all-branches');
  const findBranchProtectionTitle = () => wrapper.findByText(I18N.protectBranchTitle);
  const findAllowedToMerge = () => wrapper.findByTestId('allowed-to-merge-content');
  const findAllowedToPush = () => wrapper.findByTestId('allowed-to-push-content');
  const findAllowForcePushToggle = () => wrapper.findByTestId('force-push-content');
  const findApprovalsTitle = () => wrapper.findByText(I18N.approvalsTitle);
  const findpageTitle = () => wrapper.findByText(I18N.pageTitle);
  const findStatusChecksTitle = () => wrapper.findByText(I18N.statusChecksTitle);
  const findDeleteRuleButton = () => wrapper.findByTestId('delete-rule-button');
  const findEditRuleNameButton = () => wrapper.findByTestId('edit-rule-name-button');
  const findEditRuleButton = () => wrapper.findByTestId('edit-rule-button');
  const findDeleteRuleModal = () => wrapper.findComponent(GlModal);
  const findBranchRuleModal = () => wrapper.findComponent(BranchRuleModal);
  const findBranchRuleListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findNoDataTitle = () => wrapper.findByText(I18N.noData);
  const findRuleDrawer = () => wrapper.findComponent(RuleDrawer);

  const findMatchingBranchesLink = () =>
    wrapper.findByText(
      sprintf(I18N.matchingBranchesLinkTitle, {
        total: matchingBranchesCount,
        subject: 'branches',
      }),
    );

  it('renders page title', () => {
    expect(findpageTitle().exists()).toBe(true);
  });

  it('gets the branch param from url and renders it in the view', () => {
    expect(util.getParameterByName).toHaveBeenCalledWith('branch');
    expect(findBranchName().text()).toBe('main');
  });

  it('renders the correct label if all branches are targeted with wildcard', async () => {
    jest.spyOn(util, 'getParameterByName').mockReturnValueOnce(ALL_BRANCHES_WILDCARD);
    await createComponent();

    expect(findAllBranches().text()).toBe(I18N.allBranches);
  });

  it('renders matching branches link', () => {
    const mergeUrlParams = jest.spyOn(util, 'mergeUrlParams');
    const matchingBranchesLink = findMatchingBranchesLink();

    expect(mergeUrlParams).toHaveBeenCalledWith({ state: 'all', search: `^main$` }, '');
    expect(matchingBranchesLink.exists()).toBe(true);
    expect(matchingBranchesLink.attributes().href).toBe('/branches?state=all&search=%5Emain%24');
  });

  it('renders a branch protection title', () => {
    expect(findBranchProtectionTitle().exists()).toBe(true);
  });

  it('renders a branch protection component for push rules', () => {
    expect(findAllowedToPush().props()).toMatchObject({
      header: sprintf(I18N.allowedToPushHeader, {
        total: 2,
      }),
      ...protectionMockProps,
    });
  });

  it('passes expected roles for push rules via props', () => {
    expect(findAllowedToPush().props('roles')).toEqual(protectionMockProps.roles);
  });

  it('does not render Allow force push toggle if there are no push rules set', async () => {
    await createComponent({
      branchRulesQueryHandler: jest
        .fn()
        .mockResolvedValue(branchProtectionsNoPushAccessMockResponse),
    });

    expect(findAllowForcePushToggle().exists()).toBe(false);
  });

  it.each`
    allowForcePush | iconTitle                          | description
    ${true}        | ${I18N.allowForcePushTitle}        | ${I18N.forcePushDescriptionWithDocs}
    ${false}       | ${I18N.doesNotAllowForcePushTitle} | ${I18N.forcePushDescriptionWithDocs}
  `(
    'renders force push section with the correct title and description',
    async ({ allowForcePush, iconTitle, description }) => {
      const mockResponse = branchProtectionsMockResponse;
      mockResponse.data.project.branchRules.nodes[0].branchProtection.allowForcePush = allowForcePush;
      await createComponent({
        glFeatures: { editBranchRules: true },
        branchRulesQueryHandler: jest.fn().mockResolvedValue(mockResponse),
      });

      expect(findAllowForcePushToggle().props('iconTitle')).toEqual(iconTitle);
      expect(findAllowForcePushToggle().props('description')).toEqual(description);
    },
  );

  it('renders a branch protection component for merge rules', () => {
    expect(findAllowedToMerge().props()).toMatchObject({
      header: sprintf(I18N.allowedToMergeHeader, {
        total: 2,
      }),
      ...protectionMockProps,
    });
  });

  it('passes expected roles form merge rules via props', () => {
    expect(findAllowedToMerge().props('roles')).toEqual(protectionMockProps.roles);
  });

  it('does not render a branch protection component for approvals', () => {
    expect(findApprovalsTitle().exists()).toBe(false);
  });

  it('does not render a branch protection component for status checks', () => {
    expect(findStatusChecksTitle().exists()).toBe(false);
  });

  describe('Editing branch rule', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('renders edit branch rule button', () => {
      expect(findEditRuleNameButton().text()).toBe('Edit');
    });

    it('passes correct props to the edit rule modal', () => {
      expect(findBranchRuleModal().props()).toMatchObject({
        actionPrimaryText: 'Update',
        id: 'editRuleModal',
        title: 'Update target branch',
      });
    });

    it('renders correct modal id for the edit button', () => {
      const binding = getBinding(findEditRuleNameButton().element, 'gl-modal');

      expect(binding.value).toBe(EDIT_RULE_MODAL_ID);
    });

    it('renders the correct modal content', async () => {
      await nextTick();
      expect(findBranchRuleListbox().props('items')).toHaveLength(3);
    });

    it('when edit button in the modal is clicked it makes a call to edit rule and redirects to new branch rule page', async () => {
      findBranchRuleModal().vm.$emit('primary', 'main');
      await nextTick();
      await waitForPromises();
      expect(editBranchRuleSuccessHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          input: {
            id: 'gid://gitlab/Projects/BranchRule/1',
            name: 'main',
            branchProtection: expect.anything(),
          },
        }),
      );
      await waitForPromises();
      expect(util.setUrlParams).toHaveBeenCalledWith({ branch: 'main' });
      expect(util.visitUrl).toHaveBeenCalledWith(
        '/project/Project/-/settings/repository/branch_rules?branch=main',
      );
    });
  });

  describe('Deleting branch rule', () => {
    it('renders delete rule button', () => {
      expect(findDeleteRuleButton().text()).toBe('Delete rule');
    });

    it('renders a delete modal with correct props/attributes', () => {
      expect(findDeleteRuleModal().props()).toMatchObject({
        modalId: DELETE_RULE_MODAL_ID,
        title: 'Delete branch rule?',
      });
      expect(findDeleteRuleModal().attributes('ok-title')).toBe('Delete branch rule');
    });

    it('renders correct modal id for the default action', () => {
      const binding = getBinding(findDeleteRuleButton().element, 'gl-modal');

      expect(binding.value).toBe(DELETE_RULE_MODAL_ID);
    });

    it('renders the correct modal content', () => {
      expect(findDeleteRuleModal().text()).toContain(
        'Are you sure you want to delete this branch rule? This action cannot be undone.',
      );
    });

    it('when delete button in the modal is clicked it makes a call to delete rule and redirects to overview page', async () => {
      findDeleteRuleModal().vm.$emit('ok');
      await waitForPromises();
      expect(deleteBranchRuleSuccessHandler).toHaveBeenCalledWith({
        input: { id: 'gid://gitlab/Projects/BranchRule/1' },
      });
      expect(util.visitUrl).toHaveBeenCalledWith('/-/settings/repository#branch_rules');
    });

    it('if error happens it shows an alert', async () => {
      await createComponent({
        glFeatures: { editBranchRules: true },
        branchRulesQueryHandler: branchRulesMockRequestHandler,
        deleteMutationHandler: errorHandler,
      });
      findDeleteRuleModal().vm.$emit('ok');
      await nextTick();
      await waitForPromises();
      expect(errorHandler).toHaveBeenCalledWith({
        input: { id: 'gid://gitlab/Projects/BranchRule/1' },
      });
      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        message: 'Something went wrong while deleting branch rule.',
      });
    });
  });

  describe('When rendered for predefined rules', () => {
    beforeEach(async () => {
      jest.spyOn(util, 'getParameterByName').mockReturnValueOnce('All branches');

      await createComponent({
        glFeatures: { editBranchRules: true },
        branchRulesQueryHandler: predefinedBranchRulesMockRequestHandler,
      });
    });

    it('renders the correct branch rule title', () => {
      expect(findBranchName().text()).toBe('All branches');
    });

    it('does not render edit button', () => {
      expect(findEditRuleNameButton().exists()).toBe(false);
    });

    it('does not render Protect Branch section', () => {
      expect(findBranchProtectionTitle().exists()).toBe(false);
    });
  });

  describe('Allowed to merge editing', () => {
    it('renders the edit button', () => {
      expect(findEditRuleButton().text()).toBe('Edit');
    });
    it('passes expected props to rule drawer', () => {
      expect(findRuleDrawer().props()).toMatchObject(allowedToMergeDrawerProps);
    });
    it('when edit button is clicked it opens rule drawer', async () => {
      findEditRuleButton().vm.$emit('click');
      await nextTick();
      expect(findRuleDrawer().props('isOpen')).toBe(true);
    });
    it('when save button is clicked it calls edit rule mutation', async () => {
      findRuleDrawer().vm.$emit('editRule', { accessLevel: 30 });
      await nextTick();
      expect(findRuleDrawer().props('isLoading')).toEqual(true);
      await waitForPromises();
      expect(editBranchRuleSuccessHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          input: {
            branchProtection: expect.objectContaining({
              mergeAccessLevels: {
                accessLevel: 30,
              },
            }),
            id: 'gid://gitlab/Projects/BranchRule/1',
            name: 'main',
          },
        }),
      );
      expect(findRuleDrawer().props('isLoading')).toEqual(false);
    });
  });

  describe('Allow force push editing', () => {
    it('renders force push section with the correct toggle label and description', () => {
      expect(findAllowForcePushToggle().props('label')).toEqual('Allow force push');
    });

    it('when a toggle is triggered, it goes into a loading state, then shows a toast message', async () => {
      findAllowForcePushToggle().vm.$emit('toggle', false);
      await nextTick();
      expect(findAllowForcePushToggle().props('isLoading')).toEqual(true);
      await waitForPromises();
      expect(showToast).toHaveBeenCalledTimes(1);
      expect(showToast).toHaveBeenCalledWith('Allowed force push disabled');
      expect(findAllowForcePushToggle().props('isLoading')).toEqual(false);
    });

    it('when a toggle is triggered it calls edit rule mutation', async () => {
      findAllowForcePushToggle().vm.$emit('toggle', false);
      await nextTick();
      await waitForPromises();
      expect(editBranchRuleSuccessHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          input: {
            branchProtection: expect.objectContaining({
              allowForcePush: false,
            }),
            id: 'gid://gitlab/Projects/BranchRule/1',
            name: 'main',
          },
        }),
      );
    });
  });

  describe('When rendered for a non-existing rule', () => {
    beforeEach(async () => {
      jest.spyOn(util, 'getParameterByName').mockReturnValueOnce('non-existing-rule');
      await createComponent({ glFeatures: { editBranchRules: true } });
    });

    it('shows empty state', () => {
      expect(findNoDataTitle().text()).toBe('No data to display');
    });
  });

  describe('When edit_branch_rules feature flag is disabled', () => {
    beforeEach(() => createComponent({ glFeatures: { editBranchRules: false } }));

    it('does not render delete rule button and modal', () => {
      expect(findDeleteRuleButton().exists()).toBe(false);
      expect(findDeleteRuleModal().exists()).toBe(false);
    });

    it('does not render edit rule button and modal', () => {
      expect(findEditRuleNameButton().exists()).toBe(false);
      expect(findBranchRuleModal().exists()).toBe(false);
    });

    it.each`
      allowForcePush | title                              | description
      ${true}        | ${I18N.allowForcePushTitle}        | ${I18N.forcePushIconDescription}
      ${false}       | ${I18N.doesNotAllowForcePushTitle} | ${I18N.forcePushIconDescription}
    `(
      'renders force push section with the correct title and description, when rule is `$allowForcePush`',
      async ({ allowForcePush, title, description }) => {
        const mockResponse = branchProtectionsMockResponse;
        mockResponse.data.project.branchRules.nodes[0].branchProtection.allowForcePush = allowForcePush;

        await createComponent({
          glFeatures: { editBranchRules: false },
          branchRulesQueryHandler: jest.fn().mockResolvedValue(mockResponse),
        });

        expect(findAllowForcePushToggle().props('iconTitle')).toEqual(title);
        expect(findAllowForcePushToggle().props('description')).toEqual(description);
      },
    );
  });
});
