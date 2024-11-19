# frozen_string_literal: true

class RequeueBackfillMilestoneReleasesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillMilestoneReleasesProjectId"
  DELAY_INTERVAL = 2.minutes
  TABLE_NAME = :milestone_releases
  BATCH_COLUMN = :milestone_id
  MAX_BATCH_SIZE = 150_000
  GITLAB_OPTIMIZED_BATCH_SIZE = 50_000
  GITLAB_OPTIMIZED_SUB_BATCH_SIZE = 250
  JOB_ARGS = %i[project_id releases project_id release_id]

  def up
    delete_batched_background_migration(MIGRATION, TABLE_NAME, BATCH_COLUMN, JOB_ARGS)

    queue_batched_background_migration(
      MIGRATION,
      TABLE_NAME,
      BATCH_COLUMN,
      *JOB_ARGS,
      job_interval: DELAY_INTERVAL,
      max_batch_size: MAX_BATCH_SIZE,
      batch_size: GITLAB_OPTIMIZED_BATCH_SIZE,
      sub_batch_size: GITLAB_OPTIMIZED_SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, TABLE_NAME, BATCH_COLUMN, JOB_ARGS)
  end
end
