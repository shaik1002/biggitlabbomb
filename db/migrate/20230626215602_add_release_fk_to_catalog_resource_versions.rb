# frozen_string_literal: true

class AddReleaseFkToCatalogResourceVersions < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :catalog_resource_versions, :releases, column: :release_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :catalog_resource_versions, column: :release_id
    end
  end
end
