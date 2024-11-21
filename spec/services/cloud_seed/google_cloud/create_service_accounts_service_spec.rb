# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CloudSeed::GoogleCloud::CreateServiceAccountsService, feature_category: :deployment_management do
  describe '#execute' do
    before do
      mock_google_oauth2_creds = Struct.new(:app_id, :app_secret)
                                      .new('mock-app-id', 'mock-app-secret')
      allow(Gitlab::Auth::OAuth::Provider).to receive(:config_for)
                                                .with('google_oauth2')
                                                .and_return(mock_google_oauth2_creds)

      allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |client|
        mock_service_account = Struct.new(:project_id, :unique_id, :email)
                                     .new('mock-project-id', 'mock-unique-id', 'mock-email')
        allow(client).to receive(:create_service_account)
                           .and_return(mock_service_account)

        allow(client).to receive(:create_service_account_key)
                           .and_return('mock-key')

        allow(client)
          .to receive(:grant_service_account_roles)
      end
    end

    it 'creates unprotected vars', :aggregate_failures do
      project = create(:project)

      facade_instance = instance_double(Projects::ProtectedBranchFacade)
      allow(Projects::ProtectedBranchFacade).to receive(:new).with(project: project).and_return(facade_instance)
      allow(facade_instance).to receive(:protected?).with(any_args).and_return(false)

      service = described_class.new(
        project,
        nil,
        google_oauth2_token: 'mock-token',
        gcp_project_id: 'mock-gcp-project-id',
        environment_name: '*'
      )

      response = service.execute

      expect(response.status).to eq(:success)
      expect(response.message).to eq('Service account generated successfully')
      expect(project.variables.count).to eq(3)
      expect(project.variables.first.protected).to eq(false)
      expect(project.variables.second.protected).to eq(false)
      expect(project.variables.third.protected).to eq(false)
    end

    it 'creates protected vars', :aggregate_failures do
      project = create(:project)
      facade_instance = instance_double(Projects::ProtectedBranchFacade)
      allow(Projects::ProtectedBranchFacade).to receive(:new).with(project: project).and_return(facade_instance)
      allow(facade_instance).to receive(:protected?).with(any_args).and_return(true)

      service = described_class.new(
        project,
        nil,
        google_oauth2_token: 'mock-token',
        gcp_project_id: 'mock-gcp-project-id',
        environment_name: '*'
      )

      response = service.execute

      expect(response.status).to eq(:success)
      expect(response.message).to eq('Service account generated successfully')
      expect(project.variables.count).to eq(3)
      expect(project.variables.first.protected).to eq(true)
      expect(project.variables.second.protected).to eq(true)
      expect(project.variables.third.protected).to eq(true)
    end
  end
end
