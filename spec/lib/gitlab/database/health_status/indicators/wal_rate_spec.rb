# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::HealthStatus::Indicators::WalRate, :aggregate_failures, feature_category: :database do
  before_all do
    # Some spec in this file currently fails when a sec database is configured. We plan to ensure it all functions
    # and passes prior to the sec db rollout.
    # Consult https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170283 for more info.
    skip_if_multiple_databases_are_setup(:sec)
  end

  it_behaves_like 'Prometheus Alert based health indicator' do
    let(:feature_flag) { :db_health_check_wal_rate }
    let(:sli_query_main) { 'WAL rate query for main' }
    let(:sli_query_ci) { 'WAL rate query for ci' }
    let(:slo_main) { 100 }
    let(:slo_ci) { 100 }
    let(:sli_with_good_condition) { { main: 70, ci: 70 } }
    let(:sli_with_bad_condition) { { main: 120, ci: 120 } }

    let(:prometheus_alert_db_indicators_settings) do
      {
        prometheus_api_url: prometheus_url,
        mimir_api_url: mimir_url,
        wal_rate_sli_query: {
          main: sli_query_main,
          ci: sli_query_ci
        },
        wal_rate_slo: {
          main: slo_main,
          ci: slo_ci
        }
      }
    end
  end
end
