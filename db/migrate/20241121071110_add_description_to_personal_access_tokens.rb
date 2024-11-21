# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddDescriptionToPersonalAccessTokens < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :personal_access_tokens, :description, :text
    add_text_limit :personal_access_tokens, :description, 255
  end
end
