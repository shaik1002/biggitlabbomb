

import ProtectedBadge from './protected_badge.vue';


export default {
  component: ProtectedBadge,
  title: 'vue_shared/components/badges/protected_badge',
  
};

const Template = (args, { argTypes }) => ({
  components: { ProtectedBadge },
  
  props: Object.keys(argTypes),
  template: '<ProtectedBadge v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  "tooltipText": ""
};
