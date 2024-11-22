<script>
import { Head } from '@inertiajs/vue2';
import HamlWrapper from '../HamlWrapper.vue';

export default {
  components: { Head, HamlWrapper },
  props: {
    html: {
      type: String,
      required: true,
    },
  },
  mounted() {
    import('~/pages/dashboard/milestones/index').catch((e) => {
      console.log(e);
    });
  },
};
</script>

<template>
  <div>
    <Head :title="__('Milestones')" />
    <haml-wrapper :html="html" />
  </div>
</template>
