

import CrudComponent from './crud_component.vue';


export default {
  component: CrudComponent,
  title: 'vue_shared/components/crud_component',
  
};

const Template = (args, { argTypes }) => ({
  components: { CrudComponent },
  
  props: Object.keys(argTypes),
  template: '<crud-component v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {};
