# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveJiraConnectColumnsFromApplicationSettings, migration: :gitlab_main, feature_category: :integrations do
  let(:migration) { described_class.new }
  let(:application_settings) { table(:application_settings) }

  describe '#up' do
    before do
      # Create test data
      application_settings.create!(
        jira_connect_application_key: 'test_key',
        jira_connect_proxy_url: 'http://test.com',
        jira_connect_public_key_storage_enabled: false
      )
    end

    it 'removes the check constraints and columns' do
      reversible_migration do |migration|
        migration.before -> {
          expect(application_settings.column_names).to include(
            'jira_connect_application_key',
            'jira_connect_proxy_url',
            'jira_connect_public_key_storage_enabled'
          )
        }

        migration.after -> {
          expect(application_settings.column_names).not_to include(
            'jira_connect_application_key',
            'jira_connect_proxy_url',
            'jira_connect_public_key_storage_enabled'
          )
        }
      end
    end
  end

  describe '#down' do
    it 'adds back the columns with correct attributes' do
      reversible_migration do |migration|
        migration.before -> {
          expect(application_settings.column_names).not_to include(
            'jira_connect_application_key',
            'jira_connect_proxy_url',
            'jira_connect_public_key_storage_enabled'
          )
        }

        migration.after -> {
          columns = connection.columns(:application_settings)

          jira_key_column = columns.find { |c| c.name == 'jira_connect_application_key' }
          expect(jira_key_column.type).to be(:text)

          proxy_url_column = columns.find { |c| c.name == 'jira_connect_proxy_url' }
          expect(proxy_url_column.type).to be(:text)

          storage_enabled_column = columns.find { |c| c.name == 'jira_connect_public_key_storage_enabled' }
          expect(storage_enabled_column.type).to be(:boolean)
          expect(storage_enabled_column.default).to be(false)
          expect(storage_enabled_column.null).to be(false)
        }
      end
    end

    it 'adds back the check constraints' do
      reversible_migration do |migration|
        migration.after -> {
          expect do
            application_settings.create!(
              jira_connect_proxy_url: 'a' * 256
            )
          end.to raise_error(ActiveRecord::StatementInvalid, /check_4847426287/)

          expect do
            application_settings.create!(
              jira_connect_application_key: 'a' * 256
            )
          end.to raise_error(ActiveRecord::StatementInvalid, /check_e2dd6e290a/)
        }
      end
    end
  end
end
