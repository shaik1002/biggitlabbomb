# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::DestroyPipelineService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }

  let!(:pipeline) { create(:ci_pipeline, :success, project: project, sha: project.commit.id) }

  subject { described_class.new(project, user).execute(pipeline) }

  context 'user is owner' do
    let(:user) { project.first_owner }

    it 'destroys the pipeline' do
      expect(::Ci::InternalDestroyPipelineService)
        .to receive(:new).with(pipeline).and_call_original

      subject

      expect { pipeline.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'user is not owner' do
    let(:user) { create(:user) }

    it 'raises an exception' do
      expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end
end
