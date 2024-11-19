

import CodeDropdown from './code_dropdown.vue';


export default {
  component: CodeDropdown,
  title: 'vue_shared/components/code_dropdown/code_dropdown',
  
};

const Template = (args, { argTypes }) => ({
  components: { CodeDropdown },
  
  props: Object.keys(argTypes),
  template: '<code-dropdown v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {};
