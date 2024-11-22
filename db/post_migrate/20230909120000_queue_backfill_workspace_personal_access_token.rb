# frozen_string_literal: true

class QueueBackfillWorkspacePersonalAccessToken < Gitlab::Database::Migration[2.1]
  MIGRATION = "BackfillWorkspacePersonalAccessToken"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 100
  SUB_BATCH_SIZE = 10

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  def up
    queue_batched_background_migration(
      MIGRATION,
      :workspaces,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :workspaces, :id, [])
  end
end
