# frozen_string_literal: true

class AddContentToDastScannerProfiles < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :dast_scanner_profiles, :content, :jsonb, null: false, default: {}
  end
end
