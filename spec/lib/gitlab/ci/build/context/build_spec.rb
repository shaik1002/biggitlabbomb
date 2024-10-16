# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Context::Build, feature_category: :pipeline_composition do
  let(:pipeline)        { create(:ci_pipeline) }
  let(:seed_attributes) do
    {
      name: 'some-job',
      tag_list: %w[ruby docker postgresql],
      needs_attributes: [{ name: 'setup-test-env', artifacts: true, optional: false }]
    }
  end

  subject(:context) { described_class.new(pipeline, seed_attributes) }

  shared_examples 'variables collection' do
    it { is_expected.to include('CI_COMMIT_REF_NAME' => 'master') }
    it { is_expected.to include('CI_PIPELINE_IID'    => pipeline.iid.to_s) }
    it { is_expected.to include('CI_PROJECT_PATH'    => pipeline.project.full_path) }
    it { is_expected.to include('CI_JOB_NAME'        => 'some-job') }

    context 'without passed build-specific attributes' do
      let(:context) { described_class.new(pipeline) }

      it { is_expected.to include('CI_JOB_NAME'        => nil) }
      it { is_expected.to include('CI_COMMIT_REF_NAME' => 'master') }
      it { is_expected.to include('CI_PROJECT_PATH'    => pipeline.project.full_path) }
    end

    context 'when environment:name is provided' do
      let(:seed_attributes) { { name: 'some-job', environment: 'test' } }

      it { is_expected.to include('CI_ENVIRONMENT_NAME' => 'test') }
    end
  end

  describe '#variables' do
    subject { context.variables.to_hash }

    it { expect(context.variables).to be_instance_of(Gitlab::Ci::Variables::Collection) }

    it_behaves_like 'variables collection'
  end

  describe '#variables_hash' do
    subject { context.variables_hash }

    it { expect(context.variables_hash).to be_instance_of(ActiveSupport::HashWithIndifferentAccess) }

    it_behaves_like 'variables collection'
  end
end
