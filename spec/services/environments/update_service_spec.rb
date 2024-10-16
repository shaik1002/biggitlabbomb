# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::UpdateService, feature_category: :environment_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:environment) { create(:environment, project: project) }

  let(:service) { described_class.new(project, current_user, params) }
  let(:current_user) { developer }
  let(:params) { {} }

  describe '#execute' do
    subject { service.execute(environment) }

    let(:params) { { external_url: 'https://gitlab.com/' } }

    it 'updates the external URL' do
      expect { subject }.to change { environment.reload.external_url }.to('https://gitlab.com/')
    end

    it 'returns successful response' do
      response = subject

      expect(response).to be_success
      expect(response.payload[:environment]).to eq(environment)
    end

    context 'when setting a kubernetes namespace to the environment' do
      let(:params) { { kubernetes_namespace: 'default' } }

      it 'updates the kubernetes namespace' do
        expect { subject }.to change { environment.reload.kubernetes_namespace }.to('default')
      end

      it 'returns successful response' do
        response = subject

        expect(response).to be_success
        expect(response.payload[:environment]).to eq(environment)
      end
    end

    context 'when setting a flux resource path to the environment' do
      let(:params) { { flux_resource_path: 'path/to/flux/resource' } }

      it 'updates the flux resource path' do
        expect { subject }.to change { environment.reload.flux_resource_path }.to('path/to/flux/resource')
      end

      it 'returns successful response' do
        response = subject

        expect(response).to be_success
        expect(response.payload[:environment]).to eq(environment)
      end
    end

    context 'when setting a cluster agent to the environment' do
      let_it_be(:agent_management_project) { create(:project) }
      let_it_be(:cluster_agent) { create(:cluster_agent, project: agent_management_project) }

      let!(:authorization) { create(:agent_user_access_project_authorization, project: project, agent: cluster_agent) }
      let(:params) { { cluster_agent: cluster_agent } }

      it 'returns successful response' do
        response = subject

        expect(response).to be_success
        expect(response.payload[:environment].cluster_agent).to eq(cluster_agent)
      end

      context 'when user does not have permission to read the agent' do
        let!(:authorization) { nil }

        it 'returns an error' do
          response = subject

          expect(response).to be_error
          expect(response.message).to eq('Unauthorized to access the cluster agent in this project')
          expect(response.payload[:environment]).to eq(environment)
        end
      end
    end

    context 'when unsetting a cluster agent of the environment' do
      let_it_be(:cluster_agent) { create(:cluster_agent, project: project) }

      let(:params) { { cluster_agent: nil } }

      before do
        environment.update!(cluster_agent: cluster_agent)
      end

      it 'returns successful response' do
        response = subject

        expect(response).to be_success
        expect(response.payload[:environment].cluster_agent).to be_nil
      end
    end

    context 'when params contain invalid value' do
      let(:params) { { external_url: 'http://${URL}' } }

      it 'returns an error' do
        response = subject

        expect(response).to be_error
        expect(response.message).to match_array("External url URI is invalid")
        expect(response.payload[:environment]).to eq(environment)
      end
    end

    context 'when disallowed parameter is passed' do
      let(:params) { { external_url: 'https://gitlab.com/', slug: 'prod' } }

      it 'ignores the parameter' do
        response = subject

        expect(response).to be_success
        expect(response.payload[:environment].external_url).to eq('https://gitlab.com/')
        expect(response.payload[:environment].slug).not_to eq('prod')
      end
    end

    context 'when user is reporter' do
      let(:current_user) { reporter }

      it 'returns an error' do
        response = subject

        expect(response).to be_error
        expect(response.message).to eq('Unauthorized to update the environment')
        expect(response.payload[:environment]).to eq(environment)
      end
    end
  end
end
