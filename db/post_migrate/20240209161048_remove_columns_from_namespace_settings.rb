# frozen_string_literal: true

class RemoveColumnsFromNamespaceSettings < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  enable_lock_retries!

  def up
    remove_column :namespace_settings, :delayed_project_removal, if_exists: true
    remove_column :namespace_settings, :lock_delayed_project_removal, if_exists: true
  end

  def down
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :namespace_settings, :delayed_project_removal, :boolean, if_not_exists: true
    # rubocop:enable Migration/PreventAddingColumns
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :namespace_settings, :lock_delayed_project_removal, :boolean, default: false,
      # rubocop:enable Migration/PreventAddingColumns
      null: false, if_not_exists: true
  end
end
