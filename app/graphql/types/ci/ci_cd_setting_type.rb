# frozen_string_literal: true

module Types
  module Ci
    class CiCdSettingType < BaseObject
      graphql_name 'ProjectCiCdSetting'

      authorize :manage_merge_request_settings

      field :inbound_job_token_scope_enabled,
        GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates CI/CD job tokens generated in other projects ' \
          'have restricted access to this project.',
        method: :inbound_job_token_scope_enabled?,
        authorize: :admin_project
      field :job_token_scope_enabled,
        GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates CI/CD job tokens generated in this project ' \
          'have restricted access to other projects.',
        method: :job_token_scope_enabled?,
        authorize: :admin_project
      field :keep_latest_artifact,
        GraphQL::Types::Boolean,
        null: true,
        description: 'Whether to keep the latest builds artifacts.',
        method: :keep_latest_artifacts_available?,
        authorize: :admin_project
      field :merge_pipelines_enabled,
        GraphQL::Types::Boolean,
        null: true,
        description: 'Whether merged results pipelines are enabled.',
        method: :merge_pipelines_enabled?
      field :project,
        Types::ProjectType,
        null: true,
        description: 'Project the CI/CD settings belong to.',
        authorize: :admin_project
      field :push_repository_for_job_token_allowed,
        GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates the ability to push to the original project ' \
          'repository using a job token',
        method: :push_repository_for_job_token_allowed?,
        authorize: :admin_project
      field :restrict_user_defined_variables,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether the pipeline_variables_minimum_override_role setting is enabled',
        method: :restrict_user_defined_variables,
        authorize: :admin_project
      field :ci_pipeline_variables_minimum_override_role,
        GraphQL::Types::String,
        null: false,
        description: 'The minimum role required to set variables when creating a pipeline or running a job',
        method: :pipeline_variables_minimum_override_role,
        authorize: :admin_project
    end
  end
end

Types::Ci::CiCdSettingType.prepend_mod_with('Types::Ci::CiCdSettingType')
