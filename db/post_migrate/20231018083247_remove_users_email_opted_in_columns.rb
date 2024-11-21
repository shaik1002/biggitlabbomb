# frozen_string_literal: true

class RemoveUsersEmailOptedInColumns < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    remove_column :users, :email_opted_in
    remove_column :users, :email_opted_in_ip
    remove_column :users, :email_opted_in_source_id
    remove_column :users, :email_opted_in_at
  end

  # This migration removes columns. Disabling rule only for rollback action
  # rubocop:disable Migration/AddColumnsToWideTables
  def down
    add_column :users, :email_opted_in, :boolean # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :users, :email_opted_in_ip, :string # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :users, :email_opted_in_source_id, :integer # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :users, :email_opted_in_at, :datetime_with_timezone # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
  end
  # rubocop:enable Migration/AddColumnsToWideTables
end
