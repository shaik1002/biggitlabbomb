# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'new tables missing sharding_key', feature_category: :cell do
  include ShardingKeySpecHelpers

  # Specific tables can be temporarily exempt from this requirement. You must add an issue link in a comment next to
  # the table name to remove this once a decision has been made.
  let(:allowed_to_be_missing_sharding_key) do
    [
      'compliance_framework_security_policies', # has a desired sharding key instead
      'merge_request_diff_commits_b5377a7a34', # has a desired sharding key instead
      'merge_request_diff_files_99208b8fac', # has a desired sharding key instead
      'ml_model_metadata', # has a desired sharding key instead.
      'p_ci_pipeline_variables', # https://gitlab.com/gitlab-org/gitlab/-/issues/436360
      'p_ci_stages', # https://gitlab.com/gitlab-org/gitlab/-/issues/448630
      'sbom_occurrences_vulnerabilities' # https://gitlab.com/gitlab-org/gitlab/-/issues/432900
    ]
  end

  # Specific tables can be temporarily exempt from this requirement. You must add an issue link in a comment next to
  # the table name to remove this once a decision has been made.
  let(:allowed_to_be_missing_not_null) do
    [
      *tables_with_alternative_not_null_constraint,
      'analytics_devops_adoption_segments.namespace_id',
      *['badges.project_id', 'badges.group_id'],
      *['boards.project_id', 'boards.group_id'],
      *['bulk_import_exports.project_id', 'bulk_import_exports.group_id'],
      'ci_pipeline_schedules.project_id',
      'ci_runner_namespaces.namespace_id',
      'ci_sources_pipelines.project_id',
      'ci_triggers.project_id',
      'gpg_signatures.project_id',
      *['internal_ids.project_id', 'internal_ids.namespace_id'], # https://gitlab.com/gitlab-org/gitlab/-/issues/451900
      *['labels.project_id', 'labels.group_id'], # https://gitlab.com/gitlab-org/gitlab/-/issues/434356
      'member_roles.namespace_id', # https://gitlab.com/gitlab-org/gitlab/-/issues/444161
      *['milestones.project_id', 'milestones.group_id'],
      'pages_domains.project_id', # https://gitlab.com/gitlab-org/gitlab/-/issues/442178,
      'path_locks.project_id', # https://gitlab.com/gitlab-org/gitlab/-/issues/444643
      'releases.project_id',
      'remote_mirrors.project_id', # https://gitlab.com/gitlab-org/gitlab/-/issues/444643
      'sprints.group_id',
      'subscription_add_on_purchases.namespace_id', # https://gitlab.com/gitlab-org/gitlab/-/issues/444338
      'temp_notes_backup.project_id', # https://gitlab.com/gitlab-org/gitlab/-/issues/443667'
      *['todos.project_id', 'todos.group_id']
    ]
  end

  # The following tables have multiple sharding keys and a check constraint that
  # correctly ensures at least one of the keys must be set, however the constraint
  # definition is written in a way that is difficult to verify using these specs.
  # For example:
  #   `CONSTRAINT example_constraint CHECK (((project_id IS NULL) <> (namespace_id IS NULL)))`
  let(:tables_with_alternative_not_null_constraint) do
    [
      *['protected_environments.project_id', 'protected_environments.group_id'],
      'security_orchestration_policy_configurations.project_id',
      'security_orchestration_policy_configurations.namespace_id',
      *['protected_branches.project_id', 'protected_branches.namespace_id']
    ]
  end

  # Some reasons to exempt a table:
  #   1. It has no foreign key for performance reasons
  #   2. It does not yet have a foreign key as the index is still being backfilled
  let(:allowed_to_be_missing_foreign_key) do
    [
      'ci_namespace_monthly_usages.namespace_id', # https://gitlab.com/gitlab-org/gitlab/-/issues/321400
      'ci_job_artifacts.project_id',
      'ci_namespace_monthly_usages.namespace_id', # https://gitlab.com/gitlab-org/gitlab/-/issues/321400
      'ci_builds_metadata.project_id',
      'ldap_group_links.group_id',
      'namespace_descendants.namespace_id',
      'p_batched_git_ref_updates_deletions.project_id',
      'p_catalog_resource_sync_events.project_id',
      'project_data_transfers.project_id', # https://gitlab.com/gitlab-org/gitlab/-/issues/439201
      'search_namespace_index_assignments.namespace_id_non_nullable',
      'temp_notes_backup.project_id', # https://gitlab.com/gitlab-org/gitlab/-/issues/443667'
      'value_stream_dashboard_counts.namespace_id', # https://gitlab.com/gitlab-org/gitlab/-/issues/439555
      'zoekt_indices.namespace_id',
      'zoekt_repositories.project_identifier',
      'zoekt_tasks.project_identifier'
    ]
  end

  let(:starting_from_milestone) { 16.6 }

  let(:allowed_sharding_key_referenced_tables) { %w[projects namespaces organizations] }

  it 'requires a sharding_key for all cell-local tables, after milestone 16.6', :aggregate_failures do
    tables_missing_sharding_key(starting_from_milestone: starting_from_milestone).each do |table_name|
      expect(allowed_to_be_missing_sharding_key).to include(table_name), error_message(table_name)
    end
  end

  it 'ensures all sharding_key columns exist and reference projects, namespaces or organizations',
    :aggregate_failures do
    all_tables_to_sharding_key.each do |table_name, sharding_key|
      sharding_key.each do |column_name, referenced_table_name|
        expect(column_exists?(table_name, column_name)).to eq(true),
          "Could not find sharding key column #{table_name}.#{column_name}"
        expect(referenced_table_name).to be_in(allowed_sharding_key_referenced_tables)

        if allowed_to_be_missing_foreign_key.include?("#{table_name}.#{column_name}")
          expect(has_foreign_key?(table_name, column_name)).to eq(false),
            "The column `#{table_name}.#{column_name}` has a foreign key so cannot be " \
            "allowed_to_be_missing_foreign_key. " \
            "If this is a foreign key referencing the specified table #{referenced_table_name} " \
            "then you must remove it from allowed_to_be_missing_foreign_key"
        else
          expect(has_foreign_key?(table_name, column_name, to_table_name: referenced_table_name)).to eq(true),
            "Missing a foreign key constraint for `#{table_name}.#{column_name}` " \
            "referencing #{referenced_table_name}. " \
            "All sharding keys must have a foreign key constraint"
        end
      end
    end
  end

  it 'ensures all sharding_key columns are not nullable or have a not null check constraint',
    :aggregate_failures do
    all_tables_to_sharding_key.each do |table_name, sharding_key|
      sharding_key_columns = sharding_key.keys

      if sharding_key_columns.one?
        column_name = sharding_key_columns.first
        not_nullable = not_nullable?(table_name, column_name)
        has_null_check_constraint = has_null_check_constraint?(table_name, column_name)

        if allowed_to_be_missing_not_null.include?("#{table_name}.#{column_name}")
          expect(not_nullable || has_null_check_constraint).to eq(false),
            "You must remove `#{table_name}.#{column_name}` from allowed_to_be_missing_not_null " \
            "since it now has a valid constraint."
        else
          expect(not_nullable || has_null_check_constraint).to eq(true),
            "Missing a not null constraint for `#{table_name}.#{column_name}` . " \
            "All sharding keys must be not nullable or have a NOT NULL check constraint"
        end
      else
        allowed_columns = allowed_to_be_missing_not_null & sharding_key_columns.map { |c| "#{table_name}.#{c}" }
        has_null_check_constraint = has_multi_column_null_check_constraint?(table_name, sharding_key_columns)

        if allowed_columns.present?
          if allowed_columns.length != sharding_key_columns.length
            expect(allowed_columns.length).to eq(sharding_key_columns.length),
              "`#{table_name}` has sharding keys #{sharding_key_columns.to_sentence} but " \
              "allowed_to_be_missing_not_null contains only #{allowed_columns.to_sentence}. " \
              "allowed_to_be_missing_not_null must contain all sharding key columns, or none"
          else
            expect(has_null_check_constraint).to eq(false),
              "You must remove #{allowed_columns.to_sentence} from allowed_to_be_missing_not_null " \
              "since there is now a valid constraint"
          end
        else
          expect(has_null_check_constraint).to eq(true),
            "Missing a not null constraint for #{sharding_key_columns.to_sentence} on `#{table_name}`. " \
            "All sharding keys must have a NOT NULL check constraint. For more information on constraints for " \
            "multiple columns, see https://docs.gitlab.com/ee/development/database/not_null_constraints.html#not-null-constraints-for-multiple-columns"
        end
      end
    end
  end

  it 'only allows `allowed_to_be_missing_sharding_key` to include tables that are missing a sharding_key',
    :aggregate_failures do
    allowed_to_be_missing_sharding_key.each do |exempted_table|
      expect(tables_missing_sharding_key(starting_from_milestone: starting_from_milestone)).to include(exempted_table),
        "`#{exempted_table}` is not missing a `sharding_key`. " \
        "You must remove this table from the `allowed_to_be_missing_sharding_key` list."
    end
  end

  it 'only allows `allowed_to_be_missing_not_null` to include sharding keys',
    :aggregate_failures do
    allowed_to_be_missing_not_null.each do |exemption|
      table, column = exemption.split('.')
      entry = ::Gitlab::Database::Dictionary.entry(table)

      expect(entry&.sharding_key&.keys).to include(column),
        "`#{exemption}` is not a `sharding_key`. " \
        "You must remove this entry from the `allowed_to_be_missing_not_null` list."
    end
  end

  it 'only allows `allowed_to_be_missing_foreign_key` to include sharding keys',
    :aggregate_failures do
    allowed_to_be_missing_foreign_key.each do |exemption|
      table, column = exemption.split('.')
      entry = ::Gitlab::Database::Dictionary.entry(table)

      expect(entry&.sharding_key&.keys).to include(column),
        "`#{exemption}` is not a `sharding_key`. " \
        "You must remove this entry from the `allowed_to_be_missing_foreign_key` list."
    end
  end

  it 'does not allow tables that are permanently exempted from sharding to have sharding keys' do
    tables_exempted_from_sharding.each do |entry|
      expect(entry.sharding_key).to be_nil,
        "#{entry.table_name} is exempted from sharding and hence should not have a sharding key defined"
    end
  end

  it 'allows tables that have a sharding key to only have a cell-local schema' do
    expect(tables_with_sharding_keys_not_in_cell_local_schema).to be_empty,
      "Tables: #{tables_with_sharding_keys_not_in_cell_local_schema.join(',')} have a sharding key defined, " \
      "but does not have a cell-local schema assigned. " \
      "Tables having sharding keys should have a cell-local schema like `gitlab_main_cell` or `gitlab_ci`. " \
      "Please change the `gitlab_schema` of these tables accordingly."
  end

  it 'does not allow invalid follow-up issue URLs', :aggregate_failures do
    issue_url_regex = %r{\Ahttps://gitlab\.com/gitlab-org/gitlab/-/issues/\d+\z}

    entries_with_issue_link.each do |entry|
      if entry.sharding_key.present?
        expect(entry.sharding_key_issue_url).not_to be_present,
          "You must remove `sharding_key_issue_url` from #{entry.table_name} now that it has a valid sharding key." \
      else
        expect(entry.sharding_key_issue_url).to match(issue_url_regex),
          "Invalid `sharding_key_issue_url` url for #{entry.table_name}. Please use the following format: " \
          "https://gitlab.com/gitlab-org/gitlab/-/issues/XXX"
      end
    end
  end

  private

  def error_message(table_name)
    <<~HEREDOC
      The table `#{table_name}` is missing a `sharding_key` in the `db/docs` YML file.
      Starting from GitLab #{starting_from_milestone}, we expect all new tables to define a `sharding_key`.

      To choose an appropriate sharding_key for this table please refer
      to our guidelines at https://docs.gitlab.com/ee/development/database/multiple_databases.html#defining-a-sharding-key-for-all-cell-local-tables, or consult with the Tenant Scale group.
    HEREDOC
  end

  def tables_missing_sharding_key(starting_from_milestone:)
    ::Gitlab::Database::Dictionary.entries.filter_map do |entry|
      entry.table_name if entry.sharding_key.blank? &&
        !entry.exempt_from_sharding? &&
        entry.milestone_greater_than_or_equal_to?(starting_from_milestone) &&
        ::Gitlab::Database::GitlabSchema.cell_local?(entry.gitlab_schema)
    end
  end

  def entries_with_issue_link
    ::Gitlab::Database::Dictionary.entries.select do |entry|
      entry.sharding_key_issue_url.present?
    end
  end

  def all_tables_to_sharding_key
    entries_with_sharding_key = ::Gitlab::Database::Dictionary.entries.select do |entry|
      entry.sharding_key.present?
    end

    entries_with_sharding_key.to_h do |entry|
      [entry.table_name, entry.sharding_key]
    end
  end

  def tables_exempted_from_sharding
    ::Gitlab::Database::Dictionary.entries.select(&:exempt_from_sharding?)
  end

  def tables_with_sharding_keys_not_in_cell_local_schema
    ::Gitlab::Database::Dictionary.entries.filter_map do |entry|
      entry.table_name if entry.sharding_key.present? &&
        !::Gitlab::Database::GitlabSchema.cell_local?(entry.gitlab_schema)
    end
  end
end
