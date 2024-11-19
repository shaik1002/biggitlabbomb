
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { withGitLabAPIAccess } from 'storybook_addons/gitlab_api_access';

import ConfirmForkModal from './confirm_fork_modal.vue';

Vue.use(VueApollo);

export default {
  component: ConfirmForkModal,
  title: 'vue_shared/components/web_ide/confirm_fork_modal',
  decorators: [withGitLabAPIAccess],
};

const Template = (args, { argTypes, createVueApollo }) => ({
  components: { ConfirmForkModal },
  apolloProvider: createVueApollo(),
  props: Object.keys(argTypes),
  template: '<ConfirmForkModal v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  "visible": false,
  "modalId": "modal-confirm-fork-webide",
  "forkPath": "/qa-sandbox-dcba2195acdb/qa-test-2024-11-19-15-33-01-cc96c61102059524/duo-chat-explain-code-73fba4fd468fa779/-/forks/new"
};
