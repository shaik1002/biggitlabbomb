

import ConfirmDangerModal from './confirm_danger_modal.vue';


export default {
  component: ConfirmDangerModal,
  title: 'vue_shared/components/confirm_danger/confirm_danger_modal',
  
};

const Template = (args, { argTypes }) => ({
  components: { ConfirmDangerModal },
  
  provide: {
    confirmDangerMessage, confirmButtonText, cancelButtonText: 'confirmDangerMessage, confirmButtonText, cancelButtonText'
  },props: Object.keys(argTypes),
  template: '<ConfirmDangerModal v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  "visible": null,
  "modalId": "confirm-danger-modal",
  "phrase": "gitlab-qa-2fa-sandbox-group-c357e357f9698322/group-with-2fa-b4d66bf5852da4d2",
  "confirmLoading": false,
  "modalTitle": "Are you absolutely sure?"
};
