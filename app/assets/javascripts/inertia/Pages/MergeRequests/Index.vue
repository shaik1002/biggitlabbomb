<script>
import App from '~/merge_request_dashboard/components/app.vue';

export default {
  components: { App },
  provide: {
    mergeRequestsSearchDashboardPath: './merge_requests/search', // TODO: don't hardcode path
  },
  props: {
    initialData: {
      type: Object,
      required: true,
    },
  },
  // TODO: This currently skips all the custom apollo client config
  // from app/assets/javascripts/merge_request_dashboard/index.js
  // TODO: Same for the vue-router, I guess.
};
</script>

<template>
  <div>
    <h1>Merge requests</h1>
    <App :tabs="initialData.tabs" />
  </div>
</template>
