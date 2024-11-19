

import VisibilityIcon from './visibility_icon.vue';


export default {
  component: VisibilityIcon,
  title: 'vue_shared/components/visibility_icon',
  
};

const Template = (args, { argTypes }) => ({
  components: { VisibilityIcon },
  
  props: Object.keys(argTypes),
  template: '<visibility-icon v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {};
