# frozen_string_literal: true

class EnsureTodosBigintBackfillCompletedForSelfManaged < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  def up
    return if should_skip?

    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: 'todos',
      column_name: 'id',
      job_arguments: [['note_id'], ['note_id_convert_to_bigint']]
    )
  end

  def down
    # no-op
  end

  private

  def should_skip?
    com_or_dev_or_test_but_not_jh?
  end
end
