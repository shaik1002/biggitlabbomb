<script>
import { Head } from '@inertiajs/vue2';
import TodosApp from '~/todos/components/todos_app.vue';

export default {
  components: { Head, TodosApp },
};
</script>

<template>
  <div>
    <Head :title="__('To-Do List')" />
    <todos-app />
  </div>
</template>
