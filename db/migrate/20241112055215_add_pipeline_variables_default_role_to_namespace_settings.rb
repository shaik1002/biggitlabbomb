# frozen_string_literal: true

class AddPipelineVariablesDefaultRoleToNamespaceSettings < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    add_column :namespace_settings, :pipeline_variables_default_role,
      :integer, default: NamespaceSetting::DEVELOPER_ROLE, null: false, limit: 2
  end
end
