import '~/webpack';
import Vue from 'vue';
import { createInertiaApp } from '@inertiajs/vue2';

import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

import Translate from '~/vue_shared/translate';

import installGlEmojiElement from '../behaviors/gl_emoji';
import Layout from '../inertia/Pages/Layout.vue';

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

installGlEmojiElement();

createInertiaApp({
  resolve: (name) => {
    // FIXME: The `import` below does not work like that with webpack.
    // Only vite works at the moment.
    const pages = import.meta.glob('../inertia/Pages/**/*.vue', { eager: true });
    const page = pages[`../inertia/Pages/${name}.vue`];
    page.default.layout = page.default.layout || Layout;
    return page;
  },
  title: (title) => `${title} - GitLab`,
  setup({ el, App, props, plugin }) {
    Vue.use(VueApollo);
    Vue.use(Translate);
    Vue.use(plugin);

    new Vue({
      render: (h) => h(App, props),
      apolloProvider,
    }).$mount(el);
  },
});
