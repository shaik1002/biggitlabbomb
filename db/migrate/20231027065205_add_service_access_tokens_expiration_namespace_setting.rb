# frozen_string_literal: true

class AddServiceAccessTokensExpirationNamespaceSetting < Gitlab::Database::Migration[2.2]
  milestone '16.6'

  enable_lock_retries!

  def change
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :namespace_settings, :service_access_tokens_expiration_enforced, :boolean, default: true, null: false
    # rubocop:enable Migration/PreventAddingColumns
  end
end
