# frozen_string_literal: true

class CreateContainerRegistryTagProtectionRules < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    create_table :container_registry_tag_protection_rules do |t| # rubocop:disable Migration/EnsureFactoryForTable -- factory container_registry_tag_protection_rule present but not detected
      t.references :project, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false

      t.integer :minimum_access_level_for_push, null: false, limit: 2
      t.integer :minimum_access_level_for_delete, null: false, limit: 2

      t.text :tag_name_pattern, limit: 255, null: false

      t.index [:project_id, :tag_name_pattern], unique: true,
        name: :unique_tag_protection_rules_project_id_and_tag_name_pattern
    end
  end
end
