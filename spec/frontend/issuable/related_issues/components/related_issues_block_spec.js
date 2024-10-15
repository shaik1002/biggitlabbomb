import { nextTick } from 'vue';
import { GlIcon, GlCard } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  issuable1,
  issuable2,
  issuable3,
} from 'jest/issuable/components/related_issuable_mock_data';
import { TYPE_ISSUE } from '~/issues/constants';
import RelatedIssuesBlock from '~/related_issues/components/related_issues_block.vue';
import AddIssuableForm from '~/related_issues/components/add_issuable_form.vue';
import {
  linkedIssueTypesMap,
  linkedIssueTypesTextMap,
  PathIdSeparator,
} from '~/related_issues/constants';
import RelatedIssuesList from '~/related_issues/components/related_issues_list.vue';

describe('RelatedIssuesBlock', () => {
  let wrapper;

  const findToggleButton = () => wrapper.findByTestId('toggle-links');
  const findRelatedIssuesBody = () => wrapper.findByTestId('related-issues-body');
  const findIssueCountBadgeAddButton = () => wrapper.findByTestId('related-issues-plus-button');
  const findAllRelatedIssuesList = () => wrapper.findAllComponents(RelatedIssuesList);
  const findRelatedIssuesList = (index) => findAllRelatedIssuesList().at(index);

  const createComponent = ({
    pathIdSeparator = PathIdSeparator.Issue,
    issuableType = TYPE_ISSUE,
    canAdmin = false,
    helpPath = '',
    isFetching = false,
    isFormVisible = false,
    relatedIssues = [],
    showCategorizedIssues = false,
    autoCompleteEpics = true,
    slots = '',
  } = {}) => {
    wrapper = shallowMountExtended(RelatedIssuesBlock, {
      propsData: {
        pathIdSeparator,
        issuableType,
        canAdmin,
        helpPath,
        isFetching,
        isFormVisible,
        relatedIssues,
        showCategorizedIssues,
        autoCompleteEpics,
      },
      provide: {
        reportAbusePath: '/report/abuse/path',
      },
      stubs: {
        GlCard,
      },
      slots,
    });
  };

  describe('with defaults', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      issuableType | pathIdSeparator          | titleText         | addButtonText
      ${'issue'}   | ${PathIdSeparator.Issue} | ${'Linked items'} | ${'Add a related issue'}
      ${'epic'}    | ${PathIdSeparator.Epic}  | ${'Linked epics'} | ${'Add a related epic'}
    `(
      'displays "$titleText" in the header and "$addButtonText" aria-label for add button when issuableType is set to "$issuableType"',
      ({ issuableType, pathIdSeparator, titleText, addButtonText }) => {
        createComponent({
          pathIdSeparator,
          issuableType,
          canAdmin: true,
          helpPath: '/help/user/project/issues/related_issues',
        });

        expect(wrapper.findByTestId('card-title').text()).toContain(titleText);
        expect(findIssueCountBadgeAddButton().attributes('aria-label')).toBe(addButtonText);
      },
    );

    it('unable to add new related issues', () => {
      expect(findIssueCountBadgeAddButton().exists()).toBe(false);
    });

    it('add related issues form is hidden', () => {
      expect(wrapper.find('.js-add-related-issues-form-area').exists()).toBe(false);
    });
  });

  describe('with headerText slot', () => {
    it('displays header text slot data', () => {
      const headerText = '<div>custom header text</div>';

      createComponent({ slots: { 'header-text': headerText } });

      expect(wrapper.findByTestId('card-title').html()).toContain(headerText);
    });
  });

  describe('with headerActions slot', () => {
    it('displays header actions slot data', () => {
      const headerActions = '<button data-testid="custom-button">custom button</button>';

      createComponent({ slots: { 'header-actions': headerActions } });

      expect(wrapper.findByTestId('custom-button').html()).toBe(headerActions);
    });
  });

  describe('with isFetching=true', () => {
    beforeEach(() => {
      createComponent({
        isFetching: true,
      });
    });

    it('should show `...` badge count', () => {
      expect(wrapper.vm.badgeLabel).toBe('...');
    });
  });

  describe('with canAddRelatedIssues=true', () => {
    beforeEach(() => {
      createComponent({ canAdmin: true });
    });

    it('can add new related issues', () => {
      expect(findIssueCountBadgeAddButton().exists()).toBe(true);
    });
  });

  describe('with isFormVisible=true', () => {
    beforeEach(() => {
      createComponent({ isFormVisible: true, autoCompleteEpics: false });
    });

    it('shows add related issues form', () => {
      expect(wrapper.find('.js-add-related-issues-form-area').exists()).toBe(true);
    });

    it('sets `autoCompleteEpics` to false for add-issuable-form', () => {
      expect(wrapper.findComponent(AddIssuableForm).props('autoCompleteEpics')).toBe(false);
    });
  });

  describe('showCategorizedIssues prop', () => {
    describe('when showCategorizedIssues=true', () => {
      beforeEach(() =>
        createComponent({
          showCategorizedIssues: true,
          relatedIssues: [issuable1, issuable2, issuable3],
        }),
      );

      it('should render issue tokens items', () => {
        expect(findAllRelatedIssuesList()).toHaveLength(3);
      });

      it('shows "Blocks" heading', () => {
        expect(findRelatedIssuesList(0).props('heading')).toBe(
          linkedIssueTypesTextMap[linkedIssueTypesMap.BLOCKS],
        );
      });

      it('shows "Is blocked by" heading', () => {
        expect(findRelatedIssuesList(1).props('heading')).toBe(
          linkedIssueTypesTextMap[linkedIssueTypesMap.IS_BLOCKED_BY],
        );
      });

      it('shows "Relates to" heading', () => {
        expect(findRelatedIssuesList(2).props('heading')).toBe(
          linkedIssueTypesTextMap[linkedIssueTypesMap.RELATES_TO],
        );
      });
    });

    describe('when showCategorizedIssues=false', () => {
      it('should render issues as a flat list with no header', () => {
        createComponent({
          showCategorizedIssues: false,
          relatedIssues: [issuable1, issuable2, issuable3],
        });
        expect(findAllRelatedIssuesList()).toHaveLength(1);
        expect(findRelatedIssuesList(0).props('relatedIssues')).toHaveLength(3);
        expect(findRelatedIssuesList(0).props('heading')).toBe('');
      });
    });
  });

  describe('renders correct icon when', () => {
    [
      {
        icon: 'issues',
        issuableType: 'issue',
      },
      {
        icon: 'epic',
        issuableType: 'epic',
      },
    ].forEach(({ issuableType, icon }) => {
      it(`issuableType=${issuableType} is passed`, () => {
        createComponent({
          issuableType,
        });

        const iconComponent = wrapper.findComponent(GlIcon);
        expect(iconComponent.exists()).toBe(true);
        expect(iconComponent.props('name')).toBe(icon);
      });
    });
  });

  describe('toggle', () => {
    beforeEach(() => {
      createComponent({
        relatedIssues: [issuable1, issuable2, issuable3],
      });
    });

    it('is expanded by default', () => {
      expect(findToggleButton().props('icon')).toBe('chevron-lg-up');
      expect(findToggleButton().props('disabled')).toBe(false);
      expect(findRelatedIssuesBody().exists()).toBe(true);
    });

    it('expands on click toggle button', async () => {
      findToggleButton().vm.$emit('click');
      await nextTick();

      expect(findToggleButton().props('icon')).toBe('chevron-lg-down');
      expect(findRelatedIssuesBody().exists()).toBe(false);
    });
  });

  describe('empty state', () => {
    it.each`
      issuableType  | pathIdSeparator          | showCategorizedIssues | emptyText                                                                                 | helpLinkText
      ${'issue'}    | ${PathIdSeparator.Issue} | ${false}              | ${"Link issues together to show that they're related."}                                   | ${'Learn more about linking issues'}
      ${'issue'}    | ${PathIdSeparator.Issue} | ${true}               | ${"Link issues together to show that they're related or that one is blocking others."}    | ${'Learn more about linking issues'}
      ${'incident'} | ${PathIdSeparator.Issue} | ${false}              | ${"Link incidents together to show that they're related."}                                | ${'Learn more about linking issues and incidents'}
      ${'incident'} | ${PathIdSeparator.Issue} | ${true}               | ${"Link incidents together to show that they're related or that one is blocking others."} | ${'Learn more about linking issues and incidents'}
      ${'epic'}     | ${PathIdSeparator.Epic}  | ${true}               | ${"Link epics together to show that they're related or that one is blocking others."}     | ${'Learn more about linking epics'}
    `(
      'displays "$emptyText" in the body and "$helpLinkText" aria-label for help link',
      ({ issuableType, pathIdSeparator, showCategorizedIssues, emptyText, helpLinkText }) => {
        createComponent({
          pathIdSeparator,
          issuableType,
          canAdmin: true,
          helpPath: '/help/user/project/issues/related_issues',
          showCategorizedIssues,
        });

        expect(wrapper.findByTestId('related-issues-body').text()).toContain(emptyText);
        expect(wrapper.findByTestId('help-link').attributes('aria-label')).toBe(helpLinkText);
      },
    );
  });
});
