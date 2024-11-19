

import DownloadDropdown from './download_dropdown.vue';


export default {
  component: DownloadDropdown,
  title: 'vue_shared/components/download_dropdown/download_dropdown',
  
};

const Template = (args, { argTypes }) => ({
  components: { DownloadDropdown },
  
  props: Object.keys(argTypes),
  template: '<download-dropdown v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {};
