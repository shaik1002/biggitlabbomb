# frozen_string_literal: true

class AddImportedToIssues < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def change
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :issues, :imported, :integer, default: 0, null: false, limit: 2
    # rubocop:enable Migration/PreventAddingColumns
  end
end
