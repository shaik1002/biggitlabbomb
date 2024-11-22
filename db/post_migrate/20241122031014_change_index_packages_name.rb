# frozen_string_literal: true

class ChangeIndexPackagesName < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.7'

  NEW_INDEX_NAME = :index_packages_packages_on_name_and_id
  OLD_INDEX_NAME = :package_name_index

  # rubocop:disable Migration/PreventIndexCreation -- We are redefining an index, not really adding a new one
  def up
    add_concurrent_index :packages_packages, [:name, :id], name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :packages_packages, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :packages_packages, :name, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :packages_packages, NEW_INDEX_NAME
  end
  # rubocop:enable Migration/PreventIndexCreation
end
