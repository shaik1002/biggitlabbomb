# frozen_string_literal: true

class SetOrganizationIdForBulkImportEntities < Gitlab::Database::Migration[2.2]
  DEFAULT_ORGANIZATION_ID = 1

  milestone '17.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    define_batchable_model('bulk_import_entities').each_batch(of: 10_000) do |bulk_import_entities|
      bulk_import_entities
        .where(namespace_id: nil, project_id: nil, organization_id: nil)
        .update_all(organization_id: DEFAULT_ORGANIZATION_ID)
    end
  end

  def down; end
end
