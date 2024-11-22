# frozen_string_literal: true

class AddContentToDastSiteProfiles < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :dast_site_profiles, :content, :jsonb, null: false, default: {}
  end
end
