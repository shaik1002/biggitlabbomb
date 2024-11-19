

import EntitySelect from './entity_select.vue';


export default {
  component: EntitySelect,
  title: 'vue_shared/components/entity_select/entity_select',
  
};

const Template = (args, { argTypes }) => ({
  components: { EntitySelect },
  
  props: Object.keys(argTypes),
  template: '<entity-select v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {};
