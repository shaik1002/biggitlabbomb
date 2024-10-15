# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Observability, feature_category: :error_tracking do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  describe '.observability_url' do
    let(:gitlab_url) { 'https://example.com' }

    subject { described_class.observability_url }

    before do
      stub_config_setting(url: gitlab_url)
    end

    it { is_expected.to eq('https://observe.gitlab.com') }

    context 'when on staging.gitlab.com' do
      let(:gitlab_url) { Gitlab::Saas.staging_com_url }

      it { is_expected.to eq('https://observe.staging.gitlab.com') }
    end

    context 'when overriden via ENV' do
      let(:observe_url) { 'https://example.net' }

      before do
        stub_env('OVERRIDE_OBSERVABILITY_URL', observe_url)
      end

      it { is_expected.to eq(observe_url) }
    end
  end

  describe '.oauth_url' do
    subject { described_class.oauth_url }

    it { is_expected.to eq("#{described_class.observability_url}/v1/auth/start") }
  end

  describe '.provisioning_url' do
    subject { described_class.provisioning_url(project) }

    it { is_expected.to eq("#{described_class.observability_url}/v3/tenant/#{project.id}") }
  end

  describe '.should_enable_observability_auth_scopes?' do
    subject { described_class.should_enable_observability_auth_scopes?(resource) }

    let(:parent) { build_stubbed(:group) }
    let(:resource) do
      build_stubbed(:group, parent: parent).tap do |g|
        g.namespace_settings = build_stubbed(:namespace_settings, namespace: g)
      end
    end

    feature_flags = [:observability_tracing, :observability_metrics, :observability_logs]
    flag_states = [true, false].repeated_permutation(feature_flags.length)
    flag_tests = flag_states.map { |flags| Hash[feature_flags.zip(flags)] }

    flag_tests.each do |flags|
      context "with feature flag state #{flags}" do
        before do
          flags.transform_values! { |v| v ? parent : false }
          stub_feature_flags(flags)
        end

        let(:expected_enabled) { flags.values.any? }

        describe 'when resource is group' do
          it { is_expected.to be expected_enabled }
        end

        describe 'when resource is project' do
          let(:resource) { build_stubbed(:project, namespace: parent) }

          it { is_expected.to be expected_enabled }
        end

        describe 'when resource is not a group or project' do
          let(:resource) { build_stubbed(:user) }

          it { is_expected.to be false }
        end
      end
    end
  end
end
