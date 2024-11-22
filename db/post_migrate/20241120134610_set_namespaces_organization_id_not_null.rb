# frozen_string_literal: true

class SetNamespacesOrganizationIdNotNull < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.7'

  def up
    add_not_null_constraint :namespaces, :organization_id, validate: false
  end

  def down
    remove_not_null_constraint :namespaces, :organization_id
  end
end
