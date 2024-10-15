# frozen_string_literal: true

Gitlab::Database::Partitioning.register_models(
  [
    AuditEvent,
    BatchedGitRefUpdates::Deletion,
    Ci::BuildMetadata,
    Ci::BuildExecutionConfig,
    Ci::BuildName,
    Ci::Catalog::Resources::Components::Usage,
    Ci::Catalog::Resources::SyncEvent,
    Ci::JobAnnotation,
    Ci::JobArtifact,
    Ci::PipelineVariable,
    Ci::RunnerManagerBuild,
    Ci::Stage,
    CommitStatus,
    Gitlab::Database::BackgroundMigration::BatchedJobTransitionLog,
    LooseForeignKeys::DeletedRecord,
    Users::GroupVisit,
    Users::ProjectVisit,
    WebHookLog
  ])

if Gitlab.ee?
  Gitlab::Database::Partitioning.register_models(
    [
      IncidentManagement::PendingEscalations::Alert,
      IncidentManagement::PendingEscalations::Issue,
      Security::Finding,
      Analytics::ValueStreamDashboard::Count,
      Ci::FinishedBuildChSyncEvent,
      Search::Zoekt::Task
    ])
else
  Gitlab::Database::Partitioning.register_tables(
    [
      {
        limit_connection_names: %i[main],
        table_name: 'incident_management_pending_alert_escalations',
        partitioned_column: :process_at, strategy: :monthly
      },
      {
        limit_connection_names: %i[main],
        table_name: 'incident_management_pending_issue_escalations',
        partitioned_column: :process_at, strategy: :monthly
      }
    ])
end

# The following tables are already defined as models
unless Gitlab.jh?
  Gitlab::Database::Partitioning.register_tables(
    [
      # This should be synchronized with the following model:
      # https://jihulab.com/gitlab-cn/gitlab/-/blob/main-jh/jh/app/models/phone/verification_code.rb
      {
        limit_connection_names: %i[main],
        table_name: 'verification_codes',
        partitioned_column: :created_at, strategy: :monthly
      }
    ])
end

# Enable partition management for the backfill table during merge_request_diff_commits partitioning.
# This way new partitions will be created as the trigger syncs new rows across to this table.
#
Gitlab::Database::Partitioning.register_tables(
  [
    {
      limit_connection_names: %i[main],
      table_name: 'merge_request_diff_commits_b5377a7a34',
      partitioned_column: :merge_request_diff_id, strategy: :int_range, partition_size: 200_000_000
    }
  ]
)

# Enable partition management for the backfill table during merge_request_diff_files partitioning.
# This way new partitions will be created as the trigger syncs new rows across to this table.
#
Gitlab::Database::Partitioning.register_tables(
  [
    {
      limit_connection_names: %i[main],
      table_name: 'merge_request_diff_files_99208b8fac',
      partitioned_column: :merge_request_diff_id, strategy: :int_range, partition_size: 200_000_000
    }
  ]
)
Gitlab::Database::Partitioning.sync_partitions_ignore_db_error
