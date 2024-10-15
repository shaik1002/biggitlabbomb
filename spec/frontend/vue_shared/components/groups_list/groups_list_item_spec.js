import { GlAvatarLabeled, GlIcon, GlBadge } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import GroupsListItem from '~/vue_shared/components/groups_list/groups_list_item.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import GroupListItemDeleteModal from 'ee_else_ce/vue_shared/components/groups_list/group_list_item_delete_modal.vue';
import {
  VISIBILITY_TYPE_ICON,
  VISIBILITY_LEVEL_INTERNAL_STRING,
  GROUP_VISIBILITY_TYPE,
} from '~/visibility_level/constants';
import { ACCESS_LEVEL_LABELS, ACCESS_LEVEL_NO_ACCESS_INTEGER } from '~/access_level/constants';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import { groups } from './mock_data';

describe('GroupsListItem', () => {
  let wrapper;

  const [group] = groups;

  const defaultPropsData = { group };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(GroupsListItem, {
      propsData: { ...defaultPropsData, ...propsData },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findAvatarLabeled = () => wrapper.findComponent(GlAvatarLabeled);
  const findGroupDescription = () => wrapper.findByTestId('group-description');
  const findVisibilityIcon = () => findAvatarLabeled().findComponent(GlIcon);
  const findListActions = () => wrapper.findComponent(ListActions);
  const findConfirmationModal = () => wrapper.findComponent(GroupListItemDeleteModal);
  const findAccessLevelBadge = () => wrapper.findByTestId('access-level-badge');
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);

  it('renders group avatar', () => {
    createComponent();

    const avatarLabeled = findAvatarLabeled();

    expect(avatarLabeled.props()).toMatchObject({
      label: group.fullName,
      labelLink: group.webUrl,
    });

    expect(avatarLabeled.attributes()).toMatchObject({
      'entity-id': group.id.toString(),
      'entity-name': group.fullName,
      shape: 'rect',
    });
  });

  it('renders visibility icon with tooltip', () => {
    createComponent();

    const icon = findAvatarLabeled().findComponent(GlIcon);
    const tooltip = getBinding(icon.element, 'gl-tooltip');

    expect(icon.props('name')).toBe(VISIBILITY_TYPE_ICON[VISIBILITY_LEVEL_INTERNAL_STRING]);
    expect(tooltip.value).toBe(GROUP_VISIBILITY_TYPE[VISIBILITY_LEVEL_INTERNAL_STRING]);
  });

  it('renders subgroup count', () => {
    createComponent();

    const countWrapper = wrapper.findByTestId('subgroups-count');
    const tooltip = getBinding(countWrapper.element, 'gl-tooltip');

    expect(tooltip.value).toBe(GroupsListItem.i18n.subgroups);
    expect(countWrapper.text()).toBe(group.descendantGroupsCount.toString());
    expect(countWrapper.findComponent(GlIcon).props('name')).toBe('subgroup');
  });

  it('renders projects count', () => {
    createComponent();

    const countWrapper = wrapper.findByTestId('projects-count');
    const tooltip = getBinding(countWrapper.element, 'gl-tooltip');

    expect(tooltip.value).toBe(GroupsListItem.i18n.projects);
    expect(countWrapper.text()).toBe(group.projectsCount.toString());
    expect(countWrapper.findComponent(GlIcon).props('name')).toBe('project');
  });

  it('renders members count', () => {
    createComponent();

    const countWrapper = wrapper.findByTestId('members-count');
    const tooltip = getBinding(countWrapper.element, 'gl-tooltip');

    expect(tooltip.value).toBe(GroupsListItem.i18n.directMembers);
    expect(countWrapper.text()).toBe(group.groupMembersCount.toString());
    expect(countWrapper.findComponent(GlIcon).props('name')).toBe('users');
  });

  describe('when visibility is not provided', () => {
    it('does not render visibility icon', () => {
      const { visibility, ...groupWithoutVisibility } = group;
      createComponent({
        propsData: {
          group: groupWithoutVisibility,
        },
      });

      expect(findVisibilityIcon().exists()).toBe(false);
    });
  });

  it('renders access level badge', () => {
    createComponent();

    expect(findAvatarLabeled().findComponent(GlBadge).text()).toBe(
      ACCESS_LEVEL_LABELS[group.accessLevel.integerValue],
    );
  });

  describe('when access level is not available', () => {
    const { accessLevel, ...groupWithoutAccessLevel } = group;
    beforeEach(() => {
      createComponent({
        propsData: { group: groupWithoutAccessLevel },
      });
    });

    it('does not render level role badge', () => {
      expect(findAccessLevelBadge().exists()).toBe(false);
    });
  });

  describe('when access level is `No access`', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          group: { ...group, accessLevel: { integerValue: ACCESS_LEVEL_NO_ACCESS_INTEGER } },
        },
      });
    });

    it('does not render level role badge', () => {
      expect(findAccessLevelBadge().exists()).toBe(false);
    });
  });

  describe('when group has a description', () => {
    it('renders description', () => {
      const descriptionHtml = '<p>Foo bar</p>';

      createComponent({
        propsData: {
          group: {
            ...group,
            descriptionHtml,
          },
        },
      });

      expect(findGroupDescription().element.innerHTML).toBe(descriptionHtml);
    });
  });

  describe('when group does not have a description', () => {
    it('does not render description', () => {
      createComponent({
        propsData: {
          group: {
            ...group,
            descriptionHtml: null,
          },
        },
      });

      expect(findGroupDescription().exists()).toBe(false);
    });
  });

  describe('when `showGroupIcon` prop is `true`', () => {
    describe('when `parent` attribute is `null`', () => {
      it('shows group icon', () => {
        createComponent({ propsData: { showGroupIcon: true } });

        expect(wrapper.findByTestId('group-icon').exists()).toBe(true);
      });
    });

    describe('when `parent` attribute is set', () => {
      it('shows subgroup icon', () => {
        createComponent({
          propsData: {
            showGroupIcon: true,
            group: {
              ...group,
              parent: {
                id: 'gid://gitlab/Group/35',
              },
            },
          },
        });

        expect(wrapper.findByTestId('subgroup-icon').exists()).toBe(true);
      });
    });
  });

  describe('when `showGroupIcon` prop is `false`', () => {
    it('does not show group icon', () => {
      createComponent();

      expect(wrapper.findByTestId('group-icon').exists()).toBe(false);
    });
  });

  describe('when group has actions', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          group: {
            ...group,
            actionLoadingStates: { [ACTION_DELETE]: false },
          },
        },
      });
    });

    it('displays actions dropdown', () => {
      expect(findListActions().props()).toMatchObject({
        actions: {
          [ACTION_EDIT]: {
            href: group.editPath,
          },
          [ACTION_DELETE]: {
            action: expect.any(Function),
          },
        },
        availableActions: [ACTION_EDIT, ACTION_DELETE],
      });
    });

    describe('when delete action is fired', () => {
      beforeEach(() => {
        findListActions().props('actions')[ACTION_DELETE].action();
      });

      it('displays confirmation modal with correct props', () => {
        expect(findConfirmationModal().props()).toMatchObject({
          visible: true,
          phrase: group.fullName,
          confirmLoading: false,
        });
      });

      describe('when deletion is confirmed', () => {
        beforeEach(() => {
          findConfirmationModal().vm.$emit('confirm', {
            preventDefault: jest.fn(),
          });
        });

        it('emits `delete` event', () => {
          expect(wrapper.emitted('delete')).toMatchObject([[group]]);
        });
      });

      describe('when change is fired', () => {
        beforeEach(() => {
          findConfirmationModal().vm.$emit('change', false);
        });

        it('updates visibility prop', () => {
          expect(findConfirmationModal().props('visible')).toBe(false);
        });
      });
    });
  });

  describe('when group does not have actions', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          group: {
            ...group,
            availableActions: [],
          },
        },
      });
    });

    it('does not display actions dropdown', () => {
      expect(findListActions().exists()).toBe(false);
    });

    it('does not display confirmation modal', () => {
      expect(findConfirmationModal().exists()).toBe(false);
    });
  });

  describe.each`
    timestampType                | expectedText | expectedTimeProp
    ${TIMESTAMP_TYPE_CREATED_AT} | ${'Created'} | ${group.createdAt}
    ${TIMESTAMP_TYPE_UPDATED_AT} | ${'Updated'} | ${group.updatedAt}
    ${undefined}                 | ${'Created'} | ${group.createdAt}
  `(
    'when `timestampType` prop is $timestampType',
    ({ timestampType, expectedText, expectedTimeProp }) => {
      beforeEach(() => {
        createComponent({
          propsData: {
            timestampType,
          },
        });
      });

      it('displays correct text and passes correct `time` prop to `TimeAgoTooltip`', () => {
        expect(wrapper.findByText(expectedText).exists()).toBe(true);
        expect(findTimeAgoTooltip().props('time')).toBe(expectedTimeProp);
      });
    },
  );

  describe('when timestamp type is not available in group data', () => {
    beforeEach(() => {
      const { createdAt, ...groupWithoutCreatedAt } = group;
      createComponent({
        propsData: {
          group: groupWithoutCreatedAt,
        },
      });
    });

    it('does not render timestamp', () => {
      expect(findTimeAgoTooltip().exists()).toBe(false);
    });
  });
});
