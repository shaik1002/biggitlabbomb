# frozen_string_literal: true

class RemoveImportedColumnOnMergeRequests < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def up
    remove_column :merge_requests, :imported
  end

  def down
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :merge_requests, :imported, :integer, default: 0, null: false, limit: 2
    # rubocop:enable Migration/PreventAddingColumns
  end
end
