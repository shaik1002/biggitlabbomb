<script>
import { Link } from '@inertiajs/vue2';
import { NAV_ITEM_LINK_ACTIVE_CLASS } from '../constants';
import { ariaCurrent } from '../utils';

export default {
  components: {
    Link,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isActive() {
      return this.item.is_active;
    },
    linkProps() {
      return {
        href: this.item.link,
        'aria-current': ariaCurrent(this.isActive),
      };
    },
    computedLinkClasses() {
      return {
        [NAV_ITEM_LINK_ACTIVE_CLASS]: this.isActive,
      };
    },
    targetPageIsInertiaPage() {
      return this.item.inertia_page;
    },
    currentPageIsInertiaPage() {
      return Boolean(this.$page);
    },
    useInertiaLink() {
      return this.targetPageIsInertiaPage && this.currentPageIsInertiaPage;
    },
    linkComponent() {
      return this.useInertiaLink ? Link : 'a';
    },
  },
};
</script>

<template>
  <component
    :is="linkComponent"
    v-bind="linkProps"
    :class="computedLinkClasses"
    @click="$emit('nav-link-click')"
  >
    <slot :is-active="isActive"></slot>
    <span v-show="useInertiaLink">🪄</span>
  </component>
</template>
