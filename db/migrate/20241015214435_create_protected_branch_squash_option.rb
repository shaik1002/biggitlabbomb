# frozen_string_literal: true

class CreateProtectedBranchSquashOption < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  # TODO: Split this into multiple migrations
  # https://docs.gitlab.com/ee/development/migration_style_guide.html#creating-a-new-table-when-we-have-two-foreign-keys

  def change
    create_table :protected_branch_squash_options do |t| # rubocop:disable Migration/EnsureFactoryForTable -- False positive
      t.references :project, foreign_key: true, null: false
      t.references :protected_branch, foreign_key: true, index: false
      t.integer :setting, limit: 2, null: false, default: 3
    end

    add_index(
      :protected_branch_squash_options,
      :protected_branch_id,
      unique: true,
      name: 'index_squash_options_by_protected_branch_id'
    )
    add_index(
      :protected_branch_squash_options,
      :project_id,
      name: 'index_squash_options_by_project_id',
      unique: true,
      where: 'protected_branch_id IS NULL'
    )
  end
end
