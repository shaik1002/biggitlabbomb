# frozen_string_literal: true

class EnsureNoteDiffFilesBigintBackfillIsFinishedForSelfHosts < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: 'note_diff_files',
      column_name: 'id',
      job_arguments: [['diff_note_id'], ['diff_note_id_convert_to_bigint']]
    )
  end

  def down
    # no-op
  end
end
