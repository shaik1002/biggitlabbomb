import { GlAvatarLabeled, GlIcon, GlBadge } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ListItem from '~/vue_shared/components/resource_lists/list_item.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import GroupListItemDeleteModal from 'ee_else_ce/vue_shared/components/groups_list/group_list_item_delete_modal.vue';
import GroupListItemPreventDeleteModal from '~/vue_shared/components/groups_list/group_list_item_prevent_delete_modal.vue';
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
import { groups } from '../groups_list/mock_data';

describe('ListItem', () => {
  let wrapper;

  const [resource] = groups;
  const actions = {
    [ACTION_EDIT]: {
      href: '/foo',
    },
    [ACTION_DELETE]: {
      action: jest.fn(),
    },
  };

  const defaultPropsData = {
    resource,
    timestampType: TIMESTAMP_TYPE_CREATED_AT,
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(ListItem, {
      propsData: { ...defaultPropsData, ...propsData },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      scopedSlots: {
        'avatar-meta': '<div data-testid="avatar-meta"></div>',
        stats: '<div data-testid="stats"></div>',
        footer: '<div data-testid="footer"></div>',
      },
    });
  };

  const findAvatarLabeled = () => wrapper.findComponent(GlAvatarLabeled);
  const findGroupDescription = () => wrapper.findByTestId('description');
  const findVisibilityIcon = () => findAvatarLabeled().findComponent(GlIcon);
  const findListActions = () => wrapper.findComponent(ListActions);
  const findConfirmationModal = () => wrapper.findComponent(GroupListItemDeleteModal);
  const findPreventDeleteModal = () => wrapper.findComponent(GroupListItemPreventDeleteModal);
  const findAccessLevelBadge = () => wrapper.findByTestId('access-level-badge');
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);
  const fireDeleteAction = () => findListActions().props('actions')[ACTION_DELETE].action();

  it('renders avatar', () => {
    createComponent();

    const avatarLabeled = findAvatarLabeled();

    expect(avatarLabeled.props()).toMatchObject({
      label: resource.avatarLabel,
      labelLink: resource.webUrl,
    });

    expect(avatarLabeled.attributes()).toMatchObject({
      'entity-id': resource.id.toString(),
      'entity-name': resource.fullName,
      src: resource.avatarUrl,
      shape: 'rect',
    });
  });

  it('renders stats slot', () => {
    createComponent();

    expect(wrapper.findByTestId('stats').exists()).toBe(true);
  });

  describe('when resource has a description', () => {
    it('renders description', () => {
      const descriptionHtml = '<p>Foo bar</p>';

      createComponent({
        propsData: {
          resource: {
            ...resource,
            descriptionHtml,
          },
        },
      });

      expect(findGroupDescription().element.innerHTML).toBe(descriptionHtml);
    });
  });

  describe('when resource does not have a description', () => {
    it('does not render description', () => {
      createComponent({
        propsData: {
          resource: {
            ...resource,
            descriptionHtml: null,
          },
        },
      });

      expect(findGroupDescription().exists()).toBe(false);
    });
  });

  describe('when `showIcon` prop is `true`', () => {
    it('shows icon based on `iconName` prop', () => {
      const iconName = 'group';

      createComponent({ propsData: { showGroupIcon: true, iconName } });

      expect(wrapper.findComponent(GlIcon).props('name')).toBe(iconName);
    });
  });

  describe('when `showIcon` prop is `false`', () => {
    it('does not show icon', () => {
      createComponent();

      expect(wrapper.findComponent(GlIcon).exists()).toBe(false);
    });
  });

  describe('when resource has available actions', () => {
    const resourceWithDeleteAction = {
      ...resource,
    };

    it('displays actions dropdown', () => {
      createComponent({
        propsData: {
          resource: resourceWithDeleteAction,
          actions,
        },
      });

      expect(findListActions().props()).toMatchObject({
        actions,
        availableActions: resource.availableActions,
      });
    });
  });

  describe('when actions prop has not been passed', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not display actions dropdown', () => {
      expect(findListActions().exists()).toBe(false);
    });
  });

  describe('when resource does not have available actions', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not display actions dropdown', () => {
      expect(findListActions().exists()).toBe(false);
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
