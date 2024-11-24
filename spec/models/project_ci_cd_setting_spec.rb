# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectCiCdSetting, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  describe 'validations' do
    it 'validates default_git_depth is between 0 and 1000 or nil' do
      expect(subject).to validate_numericality_of(:default_git_depth)
        .only_integer
        .is_greater_than_or_equal_to(0)
        .is_less_than_or_equal_to(1000)
        .allow_nil
    end

    it 'validates id_token_sub_claim_components with minimum length 1' do
      subject.id_token_sub_claim_components = []
      expect(subject).not_to be_valid
      expect(subject.errors[:id_token_sub_claim_components]).to include("is too short (minimum is 1 character)")
    end

    it 'validates id_token_sub_claim_components with project_path in the beginning' do
      subject.id_token_sub_claim_components = ['ref']
      expect(subject).not_to be_valid
      expect(subject.errors[:id_token_sub_claim_components])
        .to include("project_path must be the first element of the sub claim")
    end

    it 'validates invalid claim name' do
      subject.id_token_sub_claim_components = %w[project_path not_existing_claim]
      expect(subject).not_to be_valid
      expect(subject.errors[:id_token_sub_claim_components])
        .to include("not_existing_claim is not an allowed sub claim component")
    end
  end

  describe '#pipeline_variables_minimum_override_role' do
    it 'is maintainer by default' do
      expect(described_class.new.pipeline_variables_minimum_override_role).to eq('maintainer')
    end
  end

  context 'when a namespace is defined' do
    let(:namespace_settings) { create(:namespace_settings) }
    let(:group) { create(:group, namespace_settings: namespace_settings) }
    let(:project) do
      create(:project, namespace_id: group.id)
    end

    it 'is no_one_allowed by default' do
      expect(project.ci_pipeline_variables_minimum_override_role).to eq('no_one_allowed')
    end

    context 'when feature flag `change_namespace_default_role_for_pipeline_variables` is disabled' do
      before do
        stub_feature_flags(change_namespace_default_role_for_pipeline_variables: false)
      end

      it 'is developer by default' do
        expect(project.ci_pipeline_variables_minimum_override_role).to eq('developer')
      end
    end
  end

  describe '#restrict_user_defined_variables' do
    it 'is true by default' do
      expect(described_class.new.restrict_user_defined_variables).to be_truthy
    end
  end

  context 'when feature flag `change_namespace_default_role_for_pipeline_variables` is disabled' do
    before do
      stub_feature_flags(change_namespace_default_role_for_pipeline_variables: false)
    end

    describe '#pipeline_variables_minimum_override_role' do
      it 'is maintainer by default' do
        expect(described_class.new.pipeline_variables_minimum_override_role).to eq('maintainer')
      end
    end

    context 'when a namespace is defined' do
      let(:namespace_settings) { create(:namespace_settings) }
      let(:group) { create(:group, namespace_settings: namespace_settings) }
      let(:project) do
        create(:project, namespace_id: group.id)
      end

      it 'is developer by default' do
        expect(project.ci_cd_settings.pipeline_variables_minimum_override_role).to eq('developer')
      end
    end

    describe '#restrict_user_defined_variables' do
      it 'is true by default' do
        expect(described_class.new.restrict_user_defined_variables).to be_truthy
      end
    end
  end

  describe '#id_token_sub_claim_components' do
    it 'is project_path, ref_type, ref by default' do
      expect(described_class.new.id_token_sub_claim_components).to eq(%w[project_path ref_type ref])
    end
  end

  describe '#forward_deployment_enabled' do
    it 'is true by default' do
      expect(described_class.new.forward_deployment_enabled).to be_truthy
    end
  end

  describe '#push_repository_for_job_token_allowed' do
    it 'is false by default' do
      expect(described_class.new.push_repository_for_job_token_allowed).to be_falsey
    end
  end

  describe '#separated_caches' do
    it 'is true by default' do
      expect(described_class.new.separated_caches).to be_truthy
    end
  end

  describe '#default_for_inbound_job_token_scope_enabled' do
    it { is_expected.to be_inbound_job_token_scope_enabled }
  end

  describe '#default_git_depth' do
    let(:default_value) { described_class::DEFAULT_GIT_DEPTH }
    let_it_be(:project) { create(:project, :with_namespace_settings) }

    it 'sets default value for new records' do
      expect(project.ci_cd_settings.default_git_depth).to eq(default_value)
    end

    it 'does not set default value if present' do
      project.build_ci_cd_settings(default_git_depth: 0)
      project.save!

      expect(project.reload.ci_cd_settings.default_git_depth).to eq(0)
    end
  end

  describe '#keep_latest_artifacts_available?' do
    let(:attrs) { { keep_latest_artifact: project_enabled } }
    let(:project_settings) { described_class.new(attrs) }

    subject { project_settings.keep_latest_artifacts_available? }

    context 'without application setting record' do
      where(:project_enabled, :result_keep_latest_artifact) do
        false        | false
        true         | true
      end

      with_them do
        it { expect(subject).to eq(result_keep_latest_artifact) }
      end
    end

    context 'with application setting record' do
      where(:instance_enabled, :project_enabled, :result_keep_latest_artifact) do
        false         | false        | false
        false         | true         | false
        true          | false        | false
        true          | true         | true
      end

      before do
        Gitlab::CurrentSettings.current_application_settings.update!(keep_latest_artifact: instance_enabled)
      end

      with_them do
        it { expect(subject).to eq(result_keep_latest_artifact) }
      end
    end
  end
end
