

import ConfirmDanger from './confirm_danger.vue';


export default {
  component: ConfirmDanger,
  title: 'vue_shared/components/confirm_danger/confirm_danger',
  
};

const Template = (args, { argTypes }) => ({
  components: { ConfirmDanger },
  
  props: Object.keys(argTypes),
  template: '<ConfirmDanger v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  "disabled": false,
  "phrase": "gitlab-qa-2fa-sandbox-group-c357e357f9698322/group-with-2fa-b4d66bf5852da4d2",
  "buttonText": "Delete group",
  "buttonClass": "",
  "buttonTestid": "remove-group-button",
  "buttonVariant": "danger"
};
