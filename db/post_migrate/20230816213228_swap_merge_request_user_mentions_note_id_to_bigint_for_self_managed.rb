# frozen_string_literal: true

class SwapMergeRequestUserMentionsNoteIdToBigintForSelfManaged < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  TABLE_NAME = 'merge_request_user_mentions'

  def up
    return if com_or_dev_or_test_but_not_jh?
    return if temp_column_removed?(TABLE_NAME, :note_id)
    return if columns_swapped?(TABLE_NAME, :note_id)

    swap
  end

  def down
    return if com_or_dev_or_test_but_not_jh?
    return if temp_column_removed?(TABLE_NAME, :note_id)
    return unless columns_swapped?(TABLE_NAME, :note_id)

    swap
  end

  def swap
    # This will replace the existing index_merge_request_user_mentions_on_note_id
    add_concurrent_index TABLE_NAME, :note_id_convert_to_bigint, unique: true,
      name: 'index_merge_request_user_mentions_note_id_convert_to_bigint',
      where: 'note_id_convert_to_bigint IS NOT NULL'

    # This will replace the existing merge_request_user_mentions_on_mr_id_and_note_id_index
    add_concurrent_index TABLE_NAME, [:merge_request_id, :note_id_convert_to_bigint], unique: true,
      name: 'mr_user_mentions_on_mr_id_and_note_id_convert_to_bigint_index'

    # This will replace the existing merge_request_user_mentions_on_mr_id_index
    add_concurrent_index TABLE_NAME, :merge_request_id, unique: true,
      name: 'merge_request_user_mentions_on_mr_id_index_convert_to_bigint',
      where: 'note_id_convert_to_bigint IS NULL'

    # This will replace the existing fk_rails_c440b9ea31
    add_concurrent_foreign_key TABLE_NAME, :notes, column: :note_id_convert_to_bigint,
      name: 'fk_merge_request_user_mentions_note_id_convert_to_bigint',
      on_delete: :cascade

    with_lock_retries(raise_on_exhaustion: true) do
      execute "LOCK TABLE notes, #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE"

      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN note_id TO note_id_tmp"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN note_id_convert_to_bigint TO note_id"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN note_id_tmp TO note_id_convert_to_bigint"

      function_name = Gitlab::Database::UnidirectionalCopyTrigger
                        .on_table(TABLE_NAME, connection: connection)
                        .name(:note_id, :note_id_convert_to_bigint)
      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"

      execute 'DROP INDEX IF EXISTS index_merge_request_user_mentions_on_note_id'
      rename_index TABLE_NAME, 'index_merge_request_user_mentions_note_id_convert_to_bigint',
        'index_merge_request_user_mentions_on_note_id'

      execute 'DROP INDEX IF EXISTS merge_request_user_mentions_on_mr_id_and_note_id_index'
      rename_index TABLE_NAME, 'mr_user_mentions_on_mr_id_and_note_id_convert_to_bigint_index',
        'merge_request_user_mentions_on_mr_id_and_note_id_index'

      execute 'DROP INDEX IF EXISTS merge_request_user_mentions_on_mr_id_index'
      rename_index TABLE_NAME, 'merge_request_user_mentions_on_mr_id_index_convert_to_bigint',
        'merge_request_user_mentions_on_mr_id_index'

      execute "ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT IF EXISTS fk_rails_c440b9ea31"
      rename_constraint(TABLE_NAME, 'fk_merge_request_user_mentions_note_id_convert_to_bigint', 'fk_rails_c440b9ea31')
    end
  end
end
