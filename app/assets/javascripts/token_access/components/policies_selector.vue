<script>
import {
  GlCollapsibleListbox,
  GlFormRadioGroup,
  GlFormRadio,
  GlTableLite,
  GlSkeletonLoader,
  GlAlert,
} from '@gitlab/ui';
import { s__, __ } from '~/locale';
import jobTokenPoliciesByCategoryQuery from '../graphql/queries/job_token_policies_by_category.query.graphql';

export const PERMISSION_OPTION_DEFAULT = 'default';
export const PERMISSION_OPTION_FINE_GRAINED = 'fine-grained';
export const TABLE_FIELDS = [
  {
    key: 'text',
    label: s__('JobToken|Resource'),
    class: '!gl-border-none !gl-py-3 !gl-pl-0 !gl-align-middle gl-w-28',
  },
  {
    key: 'policies',
    label: __('Permissions'),
    class: '!gl-border-none !gl-py-3',
  },
];

export default {
  components: {
    GlCollapsibleListbox,
    GlFormRadioGroup,
    GlFormRadio,
    GlTableLite,
    GlSkeletonLoader,
    GlAlert,
  },
  props: {
    value: {
      type: Array,
      required: false,
      default: null,
    },
    disabled: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      selected: {},
      jobTokenPoliciesByCategory: [],
      errorMessage: '',
    };
  },
  apollo: {
    jobTokenPoliciesByCategory: {
      query: jobTokenPoliciesByCategoryQuery,
      error({ message }) {
        this.errorMessage = message;
      },
      skip() {
        return !this.isFineGrainedPermissionsSelected;
      },
    },
  },
  computed: {
    permissionType() {
      return this.value ? PERMISSION_OPTION_FINE_GRAINED : PERMISSION_OPTION_DEFAULT;
    },
    isFineGrainedPermissionsSelected() {
      return this.permissionType === PERMISSION_OPTION_FINE_GRAINED;
    },
    selectedPolicies() {
      // Return a flat list of the selected policies with empty strings filtered out.
      return Object.values(this.selected).filter(Boolean);
    },
  },
  watch: {
    jobTokenPoliciesByCategory() {
      // Initialize the selected object to: { CONTAINERS: '', DEPLOYMENT: '', JOBS: '', ... }
      this.selected = this.jobTokenPoliciesByCategory.reduce((acc, category) => {
        acc[category.value] = '';
        return acc;
      }, {});
    },
    permissionType() {
      // Clear any error messages when the permission type is changed.
      this.errorMessage = '';
    },
    selectedPolicies() {
      this.$emit('input', this.selectedPolicies);
    },
  },
  methods: {
    getDropdownItems(category) {
      return [{ text: __('None'), value: '' }, ...category.policies];
    },
    emitPermissionType(type) {
      this.$emit('input', type === PERMISSION_OPTION_FINE_GRAINED ? this.selectedPolicies : null);
    },
    selectPolicy(policy, category) {
      this.selected = { ...this.selected, [category.value]: policy };
    },
  },
  i18n: {
    defaultPermissions: s__(
      'JobToken|Use the standard permissions model based on user membership and roles',
    ),
    fineGrainedPermissions: s__(
      'JobToken|Apply permissions that grant access to individual resources',
    ),
  },
  PERMISSION_OPTION_DEFAULT,
  PERMISSION_OPTION_FINE_GRAINED,
  TABLE_FIELDS,
};
</script>

<template>
  <div>
    <label>{{ __('Permissions') }}</label>
    <gl-form-radio-group
      :checked="permissionType"
      :disabled="disabled"
      class="gl-mb-6"
      @change="emitPermissionType"
    >
      <gl-form-radio :value="$options.PERMISSION_OPTION_DEFAULT" data-testid="default-radio">
        {{ s__('JobToken|Default permissions') }}
        <template #help>{{ $options.i18n.defaultPermissions }}</template>
      </gl-form-radio>
      <gl-form-radio
        :value="$options.PERMISSION_OPTION_FINE_GRAINED"
        data-testid="fine-grained-radio"
      >
        {{ s__('JobToken|Fine-grained permissions') }}
        <template #help>{{ $options.i18n.fineGrainedPermissions }}</template>
      </gl-form-radio>
    </gl-form-radio-group>

    <gl-skeleton-loader v-if="$apollo.queries.jobTokenPoliciesByCategory.loading" />
    <gl-alert v-else-if="errorMessage" variant="danger" :dismissible="false">
      {{ errorMessage }}
    </gl-alert>
    <gl-table-lite
      v-else-if="isFineGrainedPermissionsSelected"
      :fields="$options.TABLE_FIELDS"
      :items="jobTokenPoliciesByCategory"
      fixed
    >
      <template #cell(policies)="{ item: category }">
        <gl-collapsible-listbox
          :items="getDropdownItems(category)"
          :selected="selected[category.value]"
          :disabled="disabled"
          block
          class="gl-w-20"
          @select="selectPolicy($event, category)"
        />
      </template>
    </gl-table-lite>
  </div>
</template>
