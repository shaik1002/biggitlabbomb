# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MoveJiraConnectColumnsToIntegrationsColumnInApplicationSettings, migration: :gitlab_main, feature_category: :integrations do
  let(:application_settings) { table(:application_settings) }

  before do
    application_settings.create!(
      jira_connect_application_key: 'test_key',
      jira_connect_proxy_url: 'http://proxy.example.com',
      jira_connect_public_key_storage_enabled: true,
      integrations: { 'allow_all_integrations' => true }
    )
  end

  describe '#up' do
    it 'moves Jira connect columns to integrations hash' do
      migrate!

      settings = application_settings.first
      expect(settings.integrations).to include(
        'allow_all_integrations' => true,
        'jira_connect_application_key' => 'test_key',
        'jira_connect_proxy_url' => 'http://proxy.example.com',
        'jira_connect_public_key_storage_enabled' => true
      )
    end
  end

  describe '#down' do
    before do
      migrate!
      described_class.new.down
    end

    it 'moves data back to original columns' do
      settings = application_settings.first

      expect(settings.jira_connect_application_key).to eq('test_key')
      expect(settings.jira_connect_proxy_url).to eq('http://proxy.example.com')
      expect(settings.jira_connect_public_key_storage_enabled).to be(true)
      expect(settings.integrations).to eq({ 'allow_all_integrations' => true })
    end
  end
end
