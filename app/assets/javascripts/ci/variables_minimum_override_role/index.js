import Vue from 'vue';
import VueApollo from 'vue-apollo';
import MinimumOverrideRole from '~/ci/variables_minimum_override_role/minimum_override_role.vue';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default (containerId = 'js-ci-variables-minimum-override-role-app') => {
  const containerEl = document.getElementById(containerId);

  if (!containerEl) {
    return false;
  }

  const { fullPath, helpPagePath } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    apolloProvider,
    provide: {
      fullPath,
      helpPagePath,
    },
    render(createElement) {
      return createElement(MinimumOverrideRole);
    },
  });
};
