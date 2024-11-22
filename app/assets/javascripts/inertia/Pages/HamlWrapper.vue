<script>
export default {
  props: {
    html: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div v-html="html"></div>
</template>
