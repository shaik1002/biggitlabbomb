# frozen_string_literal: true

class AddRemoveDormantMembersToNamespaceSettings < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :namespace_settings, :remove_dormant_members, :boolean, default: false, null: false
    # rubocop:enable Migration/PreventAddingColumns
  end
end
