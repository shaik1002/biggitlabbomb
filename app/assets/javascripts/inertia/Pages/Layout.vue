<script>
// import { parseBoolean } from '~/lib/utils/common_utils';
import { GlBreadcrumb } from '@gitlab/ui';
import createStore from '~/super_sidebar/components/global_search/store';
import SuperSidebar from '~/super_sidebar/components/super_sidebar.vue';
import {
  bindSuperSidebarCollapsedEvents,
  initSuperSidebarCollapsedState,
} from '~/super_sidebar/super_sidebar_collapsed_state_manager';

export default {
  components: {
    GlBreadcrumb,
    SuperSidebar,
  },
  // TODO: fill provide and store with real data
  provide: {
    rootPath: '/',
    toggleNewNavEndpoint: '/',
    isImpersonating: false, // parseBoolean(this.sidebarData.is_impersonating),
    commandPaletteCommands: [],
    commandPaletteLinks: [],
    contextSwitcherLinks: [],

    showTrialWidget: false,
    showTrialStatusWidget: false,
    showDuoProTrialStatusWidget: false,
    isSaas: false,
  },
  store: createStore({
    searchPath: '',
    issuesPath: '',
    mrPath: '',
    autocompletePath: '',
    searchContext: '',
    search: '',
  }),
  props: {
    breadcrumbItems: {
      type: Array,
      required: false,
      default: () => [],
    },
    sidebarData: {
      type: Object,
      required: true,
    },
  },
  mounted() {
    bindSuperSidebarCollapsedEvents(false);
    initSuperSidebarCollapsedState(false);
  },
};
</script>

<template>
  <main class="layout-page page-with-super-sidebar">
    <super-sidebar :sidebarData="sidebarData" />
    <header class="top-bar-fixed container-fluid">
      <div class="top-bar-container gl-flex gl-items-center gl-gap-2">
        <gl-breadcrumb :items="$page.props.breadcrumbs" class="gl-flex-grow" />
      </div>
    </header>
    <div class="container-fluid container-limited">
      <article class="content-wrapper">
        <slot />
      </article>
    </div>
  </main>
</template>

<style scoped>
article {
  margin-top: 60px; /* TODO: properly */
}
</style>
