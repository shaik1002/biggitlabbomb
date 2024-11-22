<script>
import { __ } from '~/locale';

export default {
  name: 'WikiNotesActivityHeader',
  computed: {
    headerText() {
      return __('Activity');
    },
  },
};
</script>
<template>
  <div
    class="gl-flex gl-flex-col gl-justify-between gl-pb-3 gl-pt-5 sm:gl-flex-row sm:gl-items-center"
  >
    <h2 class="gl-m-0 gl-text-size-h1">{{ headerText }}</h2>
  </div>
</template>
