# frozen_string_literal: true

class CreateTableAiCodeReviewTemplates < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    create_table :ai_code_review_templates do |t|
      t.bigint :project_id, null: false
      t.string :template_name, null: false
      t.text :content, null: false

      t.timestamps null: false
    end
  end
end
