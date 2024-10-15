# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RecalculateDoraDeploymentFrequencyScore, feature_category: :dora_metrics do
  describe '#perform', :freeze_time do
    let(:environments) { table(:environments) }
    let(:namespaces) { table(:namespaces) }
    let(:projects) { table(:projects) }
    let(:performance_scores) { table(:dora_performance_scores) }
    let(:daily_metrics) { table(:dora_daily_metrics) }

    let!(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
    let!(:project) do
      projects.create!(namespace_id: namespace.id, name: 'foo', project_namespace_id: namespace.id)
    end

    let!(:production) { environments.create!(project_id: project.id, tier: 0, name: 'prod', slug: 'prod') }
    let!(:staging) { environments.create!(project_id: project.id, tier: 1, name: 'stg', slug: 'stg') }

    let!(:high_performance_score) do
      performance_scores.create!(project_id: project.id, date: 30.days.ago.beginning_of_month,
        deployment_frequency: 30).tap do |s|
        daily_metrics.create!(project_id: project.id, environment_id: production.id, deployment_frequency: 100,
          date: s.date)
        daily_metrics.create!(project_id: project.id, environment_id: staging.id, deployment_frequency: 0, date: s.date)
      end
    end

    let!(:mid_performance_score) do
      performance_scores.create!(project_id: project.id, date: 90.days.ago.beginning_of_month,
        deployment_frequency: 30).tap do |s|
        daily_metrics.create!(project_id: project.id, environment_id: production.id, deployment_frequency: 15,
          date: s.date)
        daily_metrics.create!(project_id: project.id, environment_id: production.id, deployment_frequency: 100,
          date: s.date - 1)
        daily_metrics.create!(project_id: project.id, environment_id: staging.id, deployment_frequency: 100,
          date: s.date)
      end
    end

    let!(:low_performance_score) do
      performance_scores.create!(project_id: project.id, date: 180.days.ago.beginning_of_month,
        deployment_frequency: 30).tap do |s|
        daily_metrics.create!(project_id: project.id, environment_id: production.id, deployment_frequency: 0,
          date: s.date)
        daily_metrics.create!(project_id: project.id, environment_id: production.id, deployment_frequency: 100,
          date: s.date - 1)
        daily_metrics.create!(project_id: project.id, environment_id: staging.id, deployment_frequency: 100,
          date: s.date)
      end
    end

    let!(:low_performance_score_2) do
      # score with no daily metrics
      performance_scores.create!(project_id: project.id, date: 240.days.ago.beginning_of_month,
        deployment_frequency: 30)
    end

    subject(:migration) do
      described_class.new(
        start_id: performance_scores.order(id: :asc).first.id,
        end_id: performance_scores.order(id: :asc).last.id,
        batch_table: :dora_performance_scores,
        batch_column: :id,
        sub_batch_size: 200,
        pause_ms: 2.minutes,
        connection: ApplicationRecord.connection
      )
    end

    it 'updates deployment frequency score with correct value' do
      migration.perform

      expect(high_performance_score.reload.deployment_frequency).to eq(30)
      expect(mid_performance_score.reload.deployment_frequency).to eq(20)
      expect(low_performance_score.reload.deployment_frequency).to eq(10)
      expect(low_performance_score_2.reload.deployment_frequency).to eq(10)
    end
  end
end
