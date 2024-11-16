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
import jobTokenPoliciesQuery from '../graphql/queries/job_token_policies.query.graphql';

const PERMISSION_OPTION_DEFAULT = 'default';
const PERMISSION_OPTION_CUSTOM = 'custom';
const TABLE_FIELDS = [
  {
    key: 'text',
    label: s__('JobToken|Resource'),
    class: '!gl-border-none !gl-py-3 !gl-pl-0 !gl-align-middle gl-w-28',
  },
  { key: 'policies', label: __('Permissions'), class: '!gl-border-none !gl-py-3' },
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
      jobTokenPolicies: [],
      errorMessage: '',
    };
  },
  apollo: {
    jobTokenPolicies: {
      query: jobTokenPoliciesQuery,
      result() {
        // Initialize selected to: { CONTAINERS: '', DEPLOYMENT: '', JOBS: '', ... }
        this.jobTokenPolicies.forEach((category) => {
          this.selected[category.value] = '';
        });
        // Set the selected policies using the passed-in values.
        this.value?.forEach((policy) => {
          const category = this.policyCategoryLookup.get(policy);
          this.selected[category] = policy;
        });
      },
      error({ message }) {
        this.errorMessage = message;
      },
      skip() {
        return !this.value;
      },
    },
  },
  computed: {
    permissionType() {
      return this.value ? PERMISSION_OPTION_CUSTOM : PERMISSION_OPTION_DEFAULT;
    },
    // Mapping of policy value to its category name:
    // { READ_DEPLOYMENT: 'DEPLOYMENT', READ_JOBS: 'JOBS' }
    policyCategoryLookup() {
      return this.jobTokenPolicies.reduce((acc, category) => {
        category.policies.forEach((policy) => {
          acc[policy.value] = category.value;
        });
        return acc;
      });
    },
    selectedPolicies() {
      return Object.values(this.selected).filter(Boolean);
    },
  },
  watch: {
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
    selectPermissionType(type) {
      this.$emit('input', type === PERMISSION_OPTION_CUSTOM ? this.selectedPolicies : null);
    },
    selectPolicy(policy, category) {
      this.selected = { ...this.selected, [category.value]: policy };
    },
  },
  i18n: {
    defaultPermissions: __('Use the standard permissions model based on user membership and roles'),
    fineGrainedPermissions: __('Apply permissions that grant access to individual resources'),
  },
  PERMISSION_OPTION_DEFAULT,
  PERMISSION_OPTION_CUSTOM,
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
      @change="selectPermissionType"
    >
      <gl-form-radio :value="$options.PERMISSION_OPTION_DEFAULT">
        {{ __('Default permissions') }}
        <template #help>{{ $options.i18n.defaultPermissions }}</template>
      </gl-form-radio>
      <gl-form-radio :value="$options.PERMISSION_OPTION_CUSTOM">
        {{ __('Fine-grained permissions') }}
        <template #help>{{ $options.i18n.fineGrainedPermissions }}</template>
      </gl-form-radio>
    </gl-form-radio-group>

    <gl-skeleton-loader v-if="$apollo.queries.jobTokenPolicies.loading" />
    <gl-alert v-else-if="errorMessage" variant="danger" :dismissible="false">
      {{ errorMessage }}
    </gl-alert>
    <gl-table-lite
      v-else-if="value"
      :fields="$options.TABLE_FIELDS"
      :items="jobTokenPolicies"
      fixed
    >
      <template #cell(policies)="{ item }">
        <gl-collapsible-listbox
          :items="getDropdownItems(item)"
          :selected="selected[item.value]"
          :disabled="disabled"
          block
          class="gl-w-20"
          @select="selectPolicy($event, item)"
        />
      </template>
    </gl-table-lite>
  </div>
</template>
