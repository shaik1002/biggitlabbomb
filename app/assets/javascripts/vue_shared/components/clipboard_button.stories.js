

import ClipboardButton from './clipboard_button.vue';


export default {
  component: ClipboardButton,
  title: 'vue_shared/components/clipboard_button',
  
};

const Template = (args, { argTypes }) => ({
  components: { ClipboardButton },
  
  props: Object.keys(argTypes),
  template: '<ClipboardButton v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  "text": "c84a2e3ef6389d79\ndc1c6847bc7d93a2\nffab754820b024f8\nb01b670792c28bf0\ncd48d1f3fad668a6\nc1c17e1acacaefd7\need7c3e4f6b89cf9\n14b5e5bb086d37ad\n24ae199c869495a6\n41578b7a306e0f8d",
  "gfm": null,
  "title": "Copy codes",
  "tooltipPlacement": "top",
  "tooltipContainer": false,
  "tooltipBoundary": null,
  "cssClass": null,
  "category": "secondary",
  "size": "medium",
  "variant": "default"
};
