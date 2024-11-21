# frozen_string_literal: true

class AddOrganizationToBulkImportEntities < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  def up
    with_lock_retries { add_column :bulk_import_entities, :organization_id, :bigint }

    add_concurrent_index :bulk_import_entities, :organization_id

    add_concurrent_foreign_key(
      :bulk_import_entities,
      :organizations,
      column: :organization_id,
      foreign_key: true,
      on_delete: :cascade
    )
  end

  def down
    remove_column :bulk_import_entities, :organization_id
  end
end
