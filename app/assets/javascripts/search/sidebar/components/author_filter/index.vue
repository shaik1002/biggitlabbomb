<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import { GlFormCheckbox, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import AjaxCache from '~/lib/utils/ajax_cache';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import FilterDropdown from '~/search/sidebar/components/shared/filter_dropdown.vue';

import {
  SEARCH_ICON,
  USER_ICON,
  AUTHOR_ENDPOINT_PATH,
  AUTHOR_PARAM,
  NOT_AUTHOR_PARAM,
} from '../../constants';

export default {
  name: 'AuthorFilter',
  components: {
    FilterDropdown,
    GlFormCheckbox,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  data() {
    return {
      authors: [],
      errors: [],
      toggleState: false,
      selectedAuthorName: '',
      selectedAuthorValue: '',
      isLoading: false,
      searchTerm: '',
    };
  },
  i18n: {
    toggleTooltip: s__('GlobalSearch|Toggle if results have source branch included or excluded'),
  },
  computed: {
    ...mapState(['groupInitialJson', 'projectInitialJson', 'query']),
    showDropdownPlaceholderText() {
      return !this.selectedAuthorName ? s__('GlobalSearch|Search') : this.selectedAuthorName;
    },
    showDropdownPlaceholderIcon() {
      return !this.selectedAuthorName ? SEARCH_ICON : USER_ICON;
    },
  },
  mounted() {
    const ref = this.query?.[AUTHOR_PARAM] || this.query?.[NOT_AUTHOR_PARAM];
    this.selectedAuthorValue = ref;
    this.selectedAuthorName = ref ? this.convertValueToTextName(ref) : '';
  },
  methods: {
    ...mapActions(['setQuery', 'applyQuery']),
    getDropdownAPIEndpoint() {
      const endpoint = `${gon.relative_url_root || ''}${AUTHOR_ENDPOINT_PATH}`;
      const params = {
        current_user: true,
        active: true,
        group_id: this.groupInitialJson?.id || null,
        project_id: this.projectInitialJson?.id || null,
        search: this.searchTerm,
      };
      return mergeUrlParams(params, endpoint);
    },
    convertToListboxItems(data) {
      return data.map((item) => ({
        text: item.name,
        value: item.username,
      }));
    },
    async getCachedDropdownData() {
      this.isLoading = true;
      try {
        const data = await AjaxCache.retrieve(this.getDropdownAPIEndpoint());
        this.errors = [];
        this.isLoading = false;
        this.authors = this.convertToListboxItems(data);
      } catch (e) {
        this.isLoading = false;
        this.errors.push(this.sanitizeErrorMessage(e.message));
      }
    },
    sanitizeErrorMessage(errorMessage) {
      try {
        const message = JSON.parse(errorMessage);
        if (message.message) {
          return message.message;
        }
        return message;
      } catch (e) {
        return errorMessage;
      }
    },
    handleSelected(ref) {
      this.selectedAuthorName = this.convertValueToTextName(ref);
      this.selectedAuthorValue = ref;

      if (this.toggleState) {
        this.setQuery({ key: NOT_AUTHOR_PARAM, value: ref });
        this.setQuery({ key: AUTHOR_PARAM, value: '' });
        return;
      }
      this.setQuery({ key: AUTHOR_PARAM, value: ref });
      this.setQuery({ key: NOT_AUTHOR_PARAM, value: '' });
    },
    convertValueToTextName(ref) {
      const authorObj = this.authors.find((item) => item.value === ref);
      return authorObj?.text || ref;
    },
    changeCheckboxInput(state) {
      this.toggleState = state;
      this.handleSelected(this.selectedAuthorName);
    },
    handleSearch(searchTerm) {
      this.searchTerm = searchTerm;
      this.getCachedDropdownData();
    },
    handleReset() {
      this.toggleState = false;
      this.setQuery({ key: AUTHOR_PARAM, value: '' });
      this.setQuery({ key: NOT_AUTHOR_PARAM, value: '' });
      this.applyQuery();
    },
  },
};
</script>

<template>
  <div class="gl-relative gl-pb-0 md:gl-pt-0">
    <div class="gl-mb-2 gl-text-sm gl-font-bold" data-testid="author-filter-title">
      {{ s__('GlobalSearch|Author') }}
    </div>
    <filter-dropdown
      :list-data="authors"
      :errors="errors"
      :header-text="s__('GlobalSearch|Author')"
      :search-text="showDropdownPlaceholderText"
      :selected-item="selectedAuthorValue"
      :icon="showDropdownPlaceholderIcon"
      :is-loading="isLoading"
      :has-api-search="true"
      @search="handleSearch"
      @selected="handleSelected"
      @shown="getCachedDropdownData"
      @reset="handleReset"
    />
    <gl-form-checkbox
      v-model="toggleState"
      class="gl-mb-0 gl-inline-flex gl-w-full gl-grow gl-justify-between gl-pt-4"
      @input="changeCheckboxInput"
    >
      <span v-gl-tooltip="$options.i18n.toggleTooltip" data-testid="author-filter-tooltip">
        {{ s__('GlobalSearch|Author not included') }}
      </span>
    </gl-form-checkbox>
  </div>
</template>
