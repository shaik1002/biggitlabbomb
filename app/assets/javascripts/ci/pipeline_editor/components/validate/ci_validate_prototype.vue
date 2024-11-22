<script>
import { GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import CiLintResults from '../lint/ci_lint_results.vue';

export default {
  i18n: {
    lint: s__('PipelineEditor|Lint CI/CD sample'),
  },
  components: {
    CiLintResults,
    GlButton,
  },
  inject: ['ciLintPath'],
  props: {
    ciConfigData: {
      type: Object,
      required: true,
    },
  },
  computed: {
    errors() {
      return this.ciConfigData.errors;
    },
    isValid() {
      return this.ciConfigData.status === 'VALID';
    },
    jobs() {
      const { stages } = this.ciConfigData;
      return stages.flatMap((stage) => stage.groups.flatMap((group) => group.jobs));
    },
  },
};
</script>
<template>
  <div>
    <div class="gl-flex gl-flex-col">
      <div class="align-self-end">
        <gl-button v-if="ciLintPath" class="gl-my-3" :href="ciLintPath" data-testid="lint-button">
          {{ $options.i18n.lint }}
        </gl-button>
      </div>
      <ci-lint-results
        :is-valid="isValid"
        :jobs="jobs"
        :errors="ciConfigData.errors"
        :warnings="ciConfigData.warnings"
      />
    </div>
  </div>
</template>
