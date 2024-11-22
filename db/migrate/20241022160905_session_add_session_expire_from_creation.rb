# frozen_string_literal: true

class SessionAddSessionExpireFromCreation < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def change
    add_column :application_settings, :session_expire_from_init, :boolean, default: false, null: false
  end
end
