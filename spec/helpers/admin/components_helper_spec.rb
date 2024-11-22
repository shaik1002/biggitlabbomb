# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::ComponentsHelper, feature_category: :database do
  before_all do
    # Some spec in this file currently fails when a sec database is configured. We plan to ensure it all functions
    # and passes prior to the sec db rollout.
    # Consult https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170283 for more info.
    skip_if_multiple_databases_are_setup(:sec)
  end

  describe '#database_versions' do
    let(:expected_version) { '12.13' }
    let(:expected_hash) do
      main = {
        main: { adapter_name: 'PostgreSQL', version: expected_version }
      }
      main[:ci] = { adapter_name: 'PostgreSQL', version: expected_version } if Gitlab::Database.has_config?(:ci)
      main[:geo] = { adapter_name: 'PostgreSQL', version: expected_version } if Gitlab::Database.has_config?(:geo)
      main[:jh] = { adapter_name: 'PostgreSQL', version: expected_version } if Gitlab::Database.has_config?(:jh)

      main
    end

    subject { helper.database_versions }

    before do
      allow_next_instance_of(Gitlab::Database::Reflection) do |reflection|
        allow(reflection).to receive(:version).and_return(expected_version)
      end
    end

    it 'returns expected database data' do
      expect(subject).to eq(expected_hash)
    end
  end
end
