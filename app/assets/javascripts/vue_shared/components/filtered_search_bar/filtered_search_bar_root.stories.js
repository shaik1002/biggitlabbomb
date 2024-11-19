

import FilteredSearchBarRoot from './filtered_search_bar_root.vue';


export default {
  component: FilteredSearchBarRoot,
  title: 'vue_shared/components/filtered_search_bar/filtered_search_bar_root',
  
};

const Template = (args, { argTypes }) => ({
  components: { FilteredSearchBarRoot },
  
  props: Object.keys(argTypes),
  template: '<filtered-search-bar-root v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {};
