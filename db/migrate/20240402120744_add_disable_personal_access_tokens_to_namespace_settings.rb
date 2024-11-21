# frozen_string_literal: true

class AddDisablePersonalAccessTokensToNamespaceSettings < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  def change
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :namespace_settings, :disable_personal_access_tokens, :boolean, default: false, null: false
    # rubocop:enable Migration/PreventAddingColumns
  end
end
