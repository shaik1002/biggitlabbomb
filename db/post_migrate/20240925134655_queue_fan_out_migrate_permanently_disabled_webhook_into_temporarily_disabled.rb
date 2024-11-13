# frozen_string_literal: true

class QueueFanOutMigratePermanentlyDisabledWebhookIntoTemporarilyDisabled < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'FanOutMigratePermanentlyDisabledWebhookIntoTemporarilyDisabled'
  DELAY_INTERVAL = 4.5.minutes
  BATCH_SIZE = 500
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :web_hooks,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :web_hooks, :id, [])
  end
end
