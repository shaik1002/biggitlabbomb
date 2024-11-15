# frozen_string_literal: true

class MoveJiraConnectColumnsToIntegrationsColumnInApplicationSettings < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.7'

  def up
    ApplicationSetting.find_each do |setting|
      integrations = setting.integrations || {}

      integrations.merge!({
        'jira_connect_application_key' => setting.jira_connect_application_key,
        'jira_connect_proxy_url' => setting.jira_connect_proxy_url,
        'jira_connect_public_key_storage_enabled' => setting.jira_connect_public_key_storage_enabled
      }.compact)

      setting.update_column(:integrations, integrations)
    end
  end

  def down
    ApplicationSetting.reset_column_information

    ApplicationSetting.find_each do |setting|
      if setting.integrations
        setting.update_columns(
          jira_connect_application_key: setting.integrations['jira_connect_application_key'],
          jira_connect_proxy_url: setting.integrations['jira_connect_proxy_url'],
          jira_connect_public_key_storage_enabled: setting.integrations['jira_connect_public_key_storage_enabled']
        )

        new_integrations = setting.integrations.dup
        new_integrations.delete('jira_connect_application_key')
        new_integrations.delete('jira_connect_proxy_url')
        new_integrations.delete('jira_connect_public_key_storage_enabled')
        setting.update_column(:integrations, new_integrations)
      end
    end
  end
end
