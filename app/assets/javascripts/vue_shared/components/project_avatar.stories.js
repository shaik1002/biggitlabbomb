

import ProjectAvatar from './project_avatar.vue';


export default {
  component: ProjectAvatar,
  title: 'vue_shared/components/project_avatar',
  
};

const Template = (args, { argTypes }) => ({
  components: { ProjectAvatar },
  
  props: Object.keys(argTypes),
  template: '<project-avatar v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {};
