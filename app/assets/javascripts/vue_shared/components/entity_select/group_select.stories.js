

import GroupSelect from './group_select.vue';


export default {
  component: GroupSelect,
  title: 'vue_shared/components/entity_select/group_select',
  
};

const Template = (args, { argTypes }) => ({
  components: { GroupSelect },
  
  provide: {
    groupId: 'groupId',
    fullPath: 'gitlab-org'
  },props: Object.keys(argTypes),
  template: '<group-select v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {};
