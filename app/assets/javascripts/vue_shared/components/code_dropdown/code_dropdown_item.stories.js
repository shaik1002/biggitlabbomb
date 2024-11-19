

import CodeDropdownItem from './code_dropdown_item.vue';


export default {
  component: CodeDropdownItem,
  title: 'vue_shared/components/code_dropdown/code_dropdown_item',
  
};

const Template = (args, { argTypes }) => ({
  components: { CodeDropdownItem },
  
  props: Object.keys(argTypes),
  template: '<code-dropdown-item v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {};
