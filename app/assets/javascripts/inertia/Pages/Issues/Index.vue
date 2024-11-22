<script>
import { Head } from '@inertiajs/vue2';
import IssuesDashboardApp from '~/issues/dashboard/components/issues_dashboard_app.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

export default {
  components: {
    Head,
    IssuesDashboardApp,
  },
  provide() {
    // This is duplicated from app/assets/javascripts/issues/dashboard/index.js
    return {
      autocompleteAwardEmojisPath: this.issues.autocompleteAwardEmojisPath,
      autocompleteUsersPath: this.issues.autocompleteUsersPath,
      calendarPath: this.issues.calendarPath,
      dashboardLabelsPath: this.issues.dashboardLabelsPath,
      dashboardMilestonesPath: this.issues.dashboardMilestonesPath,
      emptyStateWithFilterSvgPath: this.issues.emptyStateWithFilterSvgPath,
      emptyStateWithoutFilterSvgPath: this.issues.emptyStateWithoutFilterSvgPath,
      hasBlockedIssuesFeature: parseBoolean(this.issues.hasBlockedIssuesFeature),
      hasIssuableHealthStatusFeature: parseBoolean(this.issues.hasIssuableHealthStatusFeature),
      hasIssueDateFilterFeature: parseBoolean(this.issues.hasIssueDateFilterFeature),
      hasIssueWeightsFeature: parseBoolean(this.issues.hasIssueWeightsFeature),
      hasOkrsFeature: parseBoolean(this.issues.hasOkrsFeature),
      hasQualityManagementFeature: parseBoolean(this.issues.hasQualityManagementFeature),
      hasScopedLabelsFeature: parseBoolean(this.issues.hasScopedLabelsFeature),
      initialSort: this.issues.initialSort,
      isPublicVisibilityRestricted: parseBoolean(this.issues.isPublicVisibilityRestricted),
      isSignedIn: parseBoolean(this.issues.isSignedIn),
      rssPath: this.issues.rssPath,
    };
  },
  props: {
    issues: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <Head :title="__('Issues')" />
    <h1>{{ __('Issues') }}</h1>
    <issues-dashboard-app />
  </div>
</template>
