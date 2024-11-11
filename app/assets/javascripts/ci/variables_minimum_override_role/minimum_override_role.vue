<script>
import { GlAlert, GlFormGroup, GlFormRadio, GlFormRadioGroup, GlLink } from '@gitlab/ui';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import { __ } from '~/locale';
import UpdatePipelineVariablesMinimumOverrideRoleProjectSetting from './graphql/mutations/update_pipeline_variables_minimum_override_role_project_setting.mutation.graphql';
import GetPipelineVariablesMinimumOverrideRoleProjectSetting from './graphql/queries/get_pipeline_variables_minimum_override_role_project_setting.query.graphql';

export default {
  errors: {
    fetchError: __('There was a problem fetching the latest minimum override setting.'),
    updateError: __('There was a problem updating the minimum override setting.'),
  },
  i18n: {
    helpText: __(
      'Select the minimum role that is required to run a new pipeline with pipeline variables.',
    ),
    helpLinkText: __('What are pipeline variables?'),
    labelText: __('Minimum role to use pipeline variables'),
    noOneHelpText: __('Pipeline variables cannot be used'),
  },
  components: {
    GlAlert,
    GlFormGroup,
    GlFormRadio,
    GlFormRadioGroup,
    GlLink,
    HelpPageLink,
  },
  inject: {
    fullPath: {
      default: '',
    },
    helpPagePath: {
      default: '',
    },
  },
  apollo: {
    minimumOverrideRole: {
      query: GetPipelineVariablesMinimumOverrideRoleProjectSetting,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        const ciCdSettings = data.project?.ciCdSettings;
        if (!ciCdSettings) {
          return;
        }
        if (ciCdSettings.restrictUserDefinedVariables) {
          return ciCdSettings.ciPipelineVariablesMinimumOverrideRole;
        }
        return 'developer';
      },
      error() {
        this.reportError(this.$options.errors.fetchError);
      },
    },
  },
  data() {
    return {
      minimumOverrideRole: null,
      errorMessage: '',
      isAlertDismissed: false,
    };
  },
  computed: {
    shouldShowAlert() {
      return this.errorMessage && !this.isAlertDismissed;
    },
  },
  methods: {
    reportError(error) {
      this.errorMessage = error;
      this.isAlertDismissed = false;
    },
    async updateSetting(value) {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: UpdatePipelineVariablesMinimumOverrideRoleProjectSetting,
          variables: {
            fullPath: this.fullPath,
            restrictUserDefinedVariables: true,
            ciPipelineVariablesMinimumOverrideRole: value,
          },
        });

        let errors = data.projectCiCdSettingsUpdate.errors;
        if (errors.length) {
          this.reportError(errors.join(', '));
        } else {
          this.isAlertDismissed = true;
        }
      } catch (error) {
        this.reportError(this.$options.errors.updateError);
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-if="shouldShowAlert"
      class="gl-mb-5"
      variant="danger"
      @dismiss="isAlertDismissed = true"
      >{{ errorMessage }}</gl-alert
    >
    <gl-form-group :label="$options.i18n.labelText" :label-description="$options.i18n.helpText">
      <template #label-description>
        {{ $options.i18n.helpText }}
        <help-page-link href="ci/variables/index" anchor="by-minimum-role">{{
          $options.i18n.helpLinkText
        }}</help-page-link>
      </template>
      <gl-form-radio-group
        v-model="minimumOverrideRole"
        name="explicit"
        :is-loading="$apollo.loading"
        @change="updateSetting"
      >
        <gl-form-radio value="no_one_allowed">
          <template #help>
            {{ $options.i18n.noOneHelpText }}
          </template>
          {{ __('No one') }}
        </gl-form-radio>
        <gl-form-radio value="owner">{{ __('Owner') }}</gl-form-radio>
        <gl-form-radio value="maintainer">{{ __('Maintainer') }} </gl-form-radio>
        <gl-form-radio value="developer">{{ __('Developer') }}</gl-form-radio>
      </gl-form-radio-group>
    </gl-form-group>
  </div>
</template>
