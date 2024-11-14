<script>
import { GlFilteredSearchToken, GlFilteredSearchSuggestion, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlFilteredSearchToken,
    GlFilteredSearchSuggestion,
    GlIcon,
  },
  props: {
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
  },
  computed: {
    sources() {
      return [
        {
          text: s__('Source|API'),
          value: 'api',
        },
        {
          text: s__('Source|Chat'),
          value: 'chat',
        },
        {
          text: s__('Source|External'),
          value: 'external',
        },
        {
          text: s__('Source|External Pull Request Event'),
          value: 'external_pull_request_event',
        },
        {
          text: s__('Source|Merge Request Event'),
          value: 'merge_request_event',
        },
        {
          text: s__('Source|Ondemand DAST Scan'),
          value: 'ondemand_dast_scan',
        },
        {
          text: s__('Source|Ondemand DAST Validation'),
          value: 'ondemand_dast_validation',
        },
        {
          text: s__('Source|Parent Pipeline'),
          value: 'parent_pipeline',
        },
        {
          text: s__('Source|Pipeline'),
          value: 'pipeline',
        },
        {
          text: s__('Source|Push'),
          value: 'push',
        },
        {
          text: s__('Source|Schedule'),
          value: 'schedule',
        },
        {
          text: s__('Source|Security Orchestration Policy'),
          value: 'security_orchestration_policy',
        },
        {
          text: s__('Source|Trigger'),
          value: 'trigger',
        },
        {
          text: s__('Source|Web'),
          value: 'web',
        },
        {
          text: s__('Source|WebIDE'),
          value: 'webide',
        },

        {
          text: s__('Source|Scan Execution Policy'),
          value: 'scan_execution_policy',
        },
        {
          text: s__('Source|Pipeline Execution Policy'),
          value: 'pipeline_execution_policy',
        },
      ];
    },
    findActiveSource() {
      return this.sources.find((source) => source.value === this.value.data);
    },
  },
};
</script>

<template>
  <gl-filtered-search-token v-bind="{ ...$props, ...$attrs }" v-on="$listeners">
    <template #view>
      <div class="gl-flex gl-items-center">
        <div :class="findActiveSource.class">
          <gl-icon :name="findActiveSource.icon" class="gl-mr-2 gl-block" />
        </div>
        <span>{{ findActiveSource.text }}</span>
      </div>
    </template>
    <template #suggestions>
      <gl-filtered-search-suggestion
        v-for="(source, index) in sources"
        :key="index"
        :value="source.value"
      >
        <div class="gl-flex" :class="source.class">
          <gl-icon :name="source.icon" class="gl-mr-3" />
          <span>{{ source.text }}</span>
        </div>
      </gl-filtered-search-suggestion>
    </template>
  </gl-filtered-search-token>
</template>
