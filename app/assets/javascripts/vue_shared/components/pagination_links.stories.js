

import PaginationLinks from './pagination_links.vue';


export default {
  component: PaginationLinks,
  title: 'vue_shared/components/pagination_links',
  
};

const Template = (args, { argTypes }) => ({
  components: { PaginationLinks },
  
  props: Object.keys(argTypes),
  template: '<pagination-links v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {};
