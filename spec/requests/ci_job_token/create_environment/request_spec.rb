# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'create_environment', feature_category: :permissions do
  let_it_be(:project) { create(:project, :private, :repository) }
  let_it_be(:job) { create(:ci_build, :running, project: project) }

  describe API::Environments do
    include ApiHelpers

    describe 'POST /projects/:id/environments' do
      subject { post api("/projects/#{project.id}/environments", job_token: job.token), params: { name: 'gitlab.com' } }

      let(:permission) { :create_environment }
      let(:resource) { Project.name }

      it_behaves_like 'an unauthorized `CI_JOB_TOKEN`'
    end
  end

  describe Mutations::Environments::Create do
    include GraphqlHelpers

    it "returns an error with the required permission", pending: "GraphQL API does not support `CI_JOB_TOKEN` yet" do
      post_graphql_mutation(graphql_mutation(:environment_create, {
        project_id: project.full_path,
        name: "example.com"
      }), token: { job_token: job.token })

      expect(response).to have_gitlab_http_status(:success)
      mutation_response = graphql_mutation_response(:environment_create)
      expect(mutation_response).to be_present
      expect(mutation_response['errors']).to be_present
    end
  end
end
