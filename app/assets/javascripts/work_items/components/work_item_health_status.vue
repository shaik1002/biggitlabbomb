<script>
import IssueHealthStatus from 'ee/related_items_tree/components/issue_health_status.vue';
import { isHealthStatusWidget } from '~/work_items/utils';

export default {
  components: {
    IssueHealthStatus,
  },
  inject: ['hasIssuableHealthStatusFeature'],
  props: {
    issue: {
      type: Object,
      required: true,
    },
  },
  computed: {
    healthStatus() {
      return (
        this.issue.healthStatus || this.issue.widgets?.find(isHealthStatusWidget)?.healthStatus
      );
    },
    showHealthStatus() {
      return this.hasIssuableHealthStatusFeature && this.healthStatus;
    },
  },
};
</script>

<template>
  <div v-if="showHealthStatus" class="gl-flex gl-items-center">
    <issue-health-status
      class="gl-text-nowrap"
      display-as-text
      text-size="sm"
      :health-status="healthStatus"
    />
    <div class="gl-mx-3 gl-hidden gl-h-5 gl-w-1 gl-bg-gray-100 md:gl-block"></div>
  </div>
</template>
