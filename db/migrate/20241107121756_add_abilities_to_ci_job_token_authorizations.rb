# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddAbilitiesToCiJobTokenAuthorizations < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    add_column :ci_job_token_authorizations, :abilities, :text, array: true, default: []
  end
end
