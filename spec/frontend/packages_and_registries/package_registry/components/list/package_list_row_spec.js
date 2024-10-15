import { GlFormCheckbox, GlSprintf, GlTruncate, GlBadge } from '@gitlab/ui';
import Vue from 'vue';
import VueRouter from 'vue-router';
import { RouterLinkStub } from '@vue/test-utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import PackagesListRow from '~/packages_and_registries/package_registry/components/list/package_list_row.vue';
import PackageTags from '~/packages_and_registries/shared/components/package_tags.vue';
import PublishMethod from '~/packages_and_registries/package_registry/components/list/publish_method.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { PACKAGE_ERROR_STATUS } from '~/packages_and_registries/package_registry/constants';

import ListItem from '~/vue_shared/components/registry/list_item.vue';
import {
  linksData,
  packageData,
  packagePipelines,
  packageProject,
  packageTags,
} from '../../mock_data';

Vue.use(VueRouter);

describe('packages_list_row', () => {
  let wrapper;

  const defaultProvide = {
    isGroupPage: false,
    canDeletePackages: true,
  };

  const packageWithoutTags = { ...packageData(), project: packageProject(), ...linksData };
  const packageWithTags = { ...packageWithoutTags, tags: { nodes: packageTags() } };

  const findPackageTags = () => wrapper.findComponent(PackageTags);
  const findDeleteDropdown = () => wrapper.findByTestId('delete-dropdown');
  const findDeleteButton = () => wrapper.findByTestId('action-delete');
  const findErrorMessage = () => wrapper.findByTestId('error-message');
  const findPackageType = () => wrapper.findByTestId('package-type');
  const findPackageLink = () => wrapper.findByTestId('details-link');
  const findWarningIcon = () => wrapper.findByTestId('warning-icon');
  const findLeftSecondaryInfos = () => wrapper.findByTestId('left-secondary-infos');
  const findPackageVersion = () => findLeftSecondaryInfos().findComponent(GlTruncate);
  const findPublishMethod = () => wrapper.findComponent(PublishMethod);
  const findRightSecondary = () => wrapper.findByTestId('right-secondary');
  const findListItem = () => wrapper.findComponent(ListItem);
  const findBulkDeleteAction = () => wrapper.findComponent(GlFormCheckbox);
  const findPackageName = () => wrapper.findByTestId('package-name');

  const mountComponent = ({
    packageEntity = packageWithoutTags,
    selected = false,
    provide = defaultProvide,
  } = {}) => {
    wrapper = shallowMountExtended(PackagesListRow, {
      provide,
      stubs: {
        ListItem,
        GlSprintf,
        TimeagoTooltip,
        RouterLink: RouterLinkStub,
        GlBadge,
      },
      propsData: {
        packageEntity,
        selected,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  it('renders', () => {
    mountComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  it('has a link to navigate to the details page', () => {
    mountComponent();

    expect(findPackageLink().props()).toMatchObject({
      to: { name: 'details', params: { id: getIdFromGraphQLId(packageWithoutTags.id) } },
    });
  });

  it('lists the package name', () => {
    mountComponent();

    expect(findPackageName().text()).toBe('@gitlab-org/package-15');
  });

  describe('tags', () => {
    it('renders package tags when a package has tags', () => {
      mountComponent({ packageEntity: packageWithTags });

      expect(findPackageTags().exists()).toBe(true);
    });

    it('does not render when there are no tags', () => {
      mountComponent();

      expect(findPackageTags().exists()).toBe(false);
    });
  });

  describe('delete dropdown', () => {
    it('does not exist when package cannot be destroyed', () => {
      mountComponent({
        packageEntity: { ...packageWithoutTags, userPermissions: { destroyPackage: false } },
      });

      expect(findDeleteDropdown().exists()).toBe(false);
    });

    it('exists when package can be destroyed', () => {
      mountComponent();

      expect(findDeleteDropdown().props()).toMatchObject({
        category: 'tertiary',
        icon: 'ellipsis_v',
        textSrOnly: true,
        noCaret: true,
        toggleText: 'More actions',
      });
    });
  });

  describe('delete button', () => {
    it('does not exist when package cannot be destroyed', () => {
      mountComponent({
        packageEntity: { ...packageWithoutTags, userPermissions: { destroyPackage: false } },
      });

      expect(findDeleteButton().exists()).toBe(false);
    });

    it('exists and has the correct text', () => {
      mountComponent({ packageEntity: packageWithoutTags });

      expect(findDeleteButton().exists()).toBe(true);
      expect(findDeleteButton().text()).toBe('Delete package');
    });

    it('emits the delete event when the delete button is clicked', () => {
      mountComponent({ packageEntity: packageWithoutTags });

      findDeleteButton().vm.$emit('action');

      expect(wrapper.emitted('delete')).toHaveLength(1);
    });
  });

  describe(`when the package is in ${PACKAGE_ERROR_STATUS} status`, () => {
    beforeEach(() => {
      mountComponent({
        packageEntity: {
          ...packageWithoutTags,
          status: PACKAGE_ERROR_STATUS,
          _links: {
            webPath: null,
          },
        },
      });
    });

    it('lists the package name', () => {
      expect(findPackageName().text()).toBe('@gitlab-org/package-15');
    });

    it('does not show the publish method', () => {
      expect(findPublishMethod().exists()).toBe(false);
    });

    it('does not show the published time', () => {
      expect(findRightSecondary().exists()).toBe(false);
    });

    it('does not have a link to navigate to the details page', () => {
      expect(findPackageLink().exists()).toBe(false);
    });

    it('has a warning icon', () => {
      const icon = findWarningIcon();
      expect(icon.props('name')).toBe('warning');
    });

    it('renders error message text', () => {
      expect(findErrorMessage().text()).toEqual(
        'Error publishing · Invalid Package: failed metadata extraction',
      );
    });

    describe('with custom error message', () => {
      it('renders error message text', () => {
        mountComponent({
          packageEntity: {
            ...packageWithoutTags,
            status: PACKAGE_ERROR_STATUS,
            statusMessage: 'custom error message',
            _links: {
              webPath: null,
            },
          },
        });

        expect(findErrorMessage().text()).toEqual('Error publishing · custom error message');
      });
    });

    it('has a delete dropdown', () => {
      expect(findDeleteDropdown().exists()).toBe(true);
    });
  });

  describe('left action template', () => {
    it('does not render checkbox if not permitted', () => {
      mountComponent({
        provide: {
          ...defaultProvide,
          canDeletePackages: false,
        },
      });

      expect(findBulkDeleteAction().exists()).toBe(false);
    });

    it('renders checkbox', () => {
      mountComponent();

      expect(findBulkDeleteAction().exists()).toBe(true);
      expect(findBulkDeleteAction().attributes('checked')).toBeUndefined();
    });

    it('emits select when checked', () => {
      mountComponent();

      findBulkDeleteAction().vm.$emit('change');

      expect(wrapper.emitted('select')).toHaveLength(1);
    });

    it('renders checkbox in selected state if selected', () => {
      mountComponent({
        selected: true,
      });

      expect(findBulkDeleteAction().attributes('checked')).toBe('true');
      expect(findListItem().props()).toMatchObject({
        selected: true,
      });
    });
  });

  describe('secondary left info', () => {
    it('has the package version', () => {
      mountComponent();

      expect(findPackageVersion().props()).toMatchObject({
        text: packageWithoutTags.version,
        withTooltip: true,
      });
    });

    it('has package type with middot', () => {
      mountComponent();

      expect(findPackageType().text()).toBe(`· ${packageWithoutTags.packageType.toLowerCase()}`);
    });
  });

  describe('right info', () => {
    it('has publish method component', () => {
      mountComponent({
        packageEntity: { ...packageWithoutTags, pipelines: { nodes: packagePipelines() } },
      });

      expect(findPublishMethod().props('pipeline')).toEqual(packagePipelines()[0]);
    });

    it('if the package is published through CI show the author name', () => {
      mountComponent({
        packageEntity: { ...packageWithoutTags, pipelines: { nodes: packagePipelines() } },
      });

      expect(findRightSecondary().text()).toBe(`Published by Administrator, 1 month ago`);
    });

    it('if the package is published manually then dont show author name', () => {
      mountComponent({
        packageEntity: { ...packageWithoutTags },
      });

      expect(findRightSecondary().text()).toBe(`Published 1 month ago`);
    });
  });

  describe('right info for a group registry', () => {
    it('if the package is published through CI show the project and author name', () => {
      mountComponent({
        provide: {
          ...defaultProvide,
          isGroupPage: true,
        },
        packageEntity: { ...packageWithoutTags, pipelines: { nodes: packagePipelines() } },
      });

      expect(findRightSecondary().text()).toBe(
        `Published to ${packageWithoutTags.project.name} by Administrator, 1 month ago`,
      );
    });

    it('if the package is published manually dont show project and the author name', () => {
      mountComponent({
        provide: {
          ...defaultProvide,
          isGroupPage: true,
        },
        packageEntity: { ...packageWithoutTags },
      });

      expect(findRightSecondary().text()).toBe(
        `Published to ${packageWithoutTags.project.name}, 1 month ago`,
      );
    });
  });

  describe('badge "protected"', () => {
    const mountComponentForBadgeProtected = ({
      packageEntityPackageProtectionRuleExists = true,
      glFeaturesPackagesProtectedPackages = true,
    } = {}) =>
      mountComponent({
        packageEntity: {
          ...packageWithoutTags,
          packageProtectionRuleExists: packageEntityPackageProtectionRuleExists,
        },
        provide: {
          ...defaultProvide,
          glFeatures: { packagesProtectedPackages: glFeaturesPackagesProtectedPackages },
        },
      });

    const findBadgeProtected = () => wrapper.findComponent(GlBadge);

    describe('when package is protected', () => {
      it('shows badge', () => {
        mountComponentForBadgeProtected();

        expect(findBadgeProtected().text()).toBe('protected');
      });

      it('binds tooltip directive', () => {
        mountComponentForBadgeProtected();

        const badgeProtectedTooltipBinding = getBinding(findBadgeProtected().element, 'gl-tooltip');
        expect(badgeProtectedTooltipBinding.value).toMatchObject({
          title: 'A protection rule exists for this package.',
        });
      });
    });

    describe('when package is not protected', () => {
      it('does not show badge', () => {
        mountComponentForBadgeProtected({ packageEntityPackageProtectionRuleExists: false });

        expect(findBadgeProtected().exists()).toBe(false);
      });
    });

    describe('when feature flag ":packages_protected_packages" disabled', () => {
      it('does not show badge', () => {
        mountComponentForBadgeProtected({ glFeaturesPackagesProtectedPackages: false });

        expect(findBadgeProtected().exists()).toBe(false);
      });
    });
  });
});
