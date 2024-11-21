# frozen_string_literal: true

class BackfillCiSourcesPipelinesSourceConversion < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  TABLE = :ci_sources_pipelines
  COLUMNS = %i[pipeline_id source_pipeline_id]
  SUB_BATCH_SIZE = 250

  def up
    backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS, sub_batch_size: SUB_BATCH_SIZE)
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
