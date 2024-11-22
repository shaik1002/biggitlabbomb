# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'read_environment', feature_category: :permissions do
  let_it_be(:permission) { :read_environment }
  let_it_be(:project) { create(:project, :private, :repository) }
  let_it_be(:job) { create(:ci_build, :running, project: project) }

  describe API::Environments do
    include ApiHelpers

    describe 'GET /projects/:id/environments' do
      subject { get api("/projects/#{project.id}/environments", job_token: job.token) }

      let_it_be(:resource) { Project.name }

      it_behaves_like 'an unauthorized `CI_JOB_TOKEN`'
    end
  end
end
