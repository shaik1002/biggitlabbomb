# frozen_string_literal: true

class RemoveJiraConnectColumnsFromApplicationSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.7'

  def up
    remove_check_constraint :application_settings, name: 'check_4847426287'
    remove_check_constraint :application_settings, name: 'check_e2dd6e290a'

    remove_column :application_settings, :jira_connect_application_key
    remove_column :application_settings, :jira_connect_proxy_url
    remove_column :application_settings, :jira_connect_public_key_storage_enabled
  end

  def down
    add_column :application_settings, :jira_connect_application_key, :text
    add_column :application_settings, :jira_connect_proxy_url, :text
    add_column :application_settings, :jira_connect_public_key_storage_enabled, :boolean, default: false, null: false

    add_check_constraint(:application_settings, 'char_length(jira_connect_proxy_url) <= 255', 'check_4847426287')
    add_check_constraint(:application_settings, 'char_length(jira_connect_application_key) <= 255', 'check_e2dd6e290a')
  end
end
