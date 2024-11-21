# frozen_string_literal: true

class AddTokenExpiryNotifyInheritedMembersGroupSetting < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :namespace_settings, :token_expiry_notify_inherited, :boolean, default: true, null: false
    # rubocop:enable Migration/PreventAddingColumns
  end
end
