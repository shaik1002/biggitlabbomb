import DrawioToolbarButton from './drawio_toolbar_button.vue';

export default {
  component: DrawioToolbarButton,
  title: 'vue_shared/components/markdown/drawio_toolbar_button',
};

const Template = (args, { argTypes }) => ({
  components: { DrawioToolbarButton },
  props: Object.keys(argTypes),
  template: '<DrawioToolbarButton v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {};
