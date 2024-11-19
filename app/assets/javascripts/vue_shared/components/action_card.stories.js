

import ActionCard from './action_card.vue';


export default {
  component: ActionCard,
  title: 'vue_shared/components/action_card',
  
};

const Template = (args, { argTypes }) => ({
  components: { ActionCard },
  
  props: Object.keys(argTypes),
  template: '<action-card v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {};
