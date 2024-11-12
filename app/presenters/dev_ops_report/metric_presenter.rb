# frozen_string_literal: true

module DevOpsReport
  class MetricPresenter < Gitlab::View::Presenter::Simple
    presents ::DevOpsReport::Metric, as: :metric

    delegate :created_at, to: :metric

    def idea_to_production_steps
      [
        IdeaToProductionStep.new(
          metric: metric,
          title: 'Idea',
          features: %w[issues]
        ),
        IdeaToProductionStep.new(
          metric: metric,
          title: 'Issue',
          features: %w[issues notes]
        ),
        IdeaToProductionStep.new(
          metric: metric,
          title: 'Plan',
          features: %w[milestones boards]
        ),
        IdeaToProductionStep.new(
          metric: metric,
          title: 'Code',
          features: %w[merge_requests]
        ),
        IdeaToProductionStep.new(
          metric: metric,
          title: 'Commit',
          features: %w[merge_requests]
        ),
        IdeaToProductionStep.new(
          metric: metric,
          title: 'Test',
          features: %w[ci_pipelines]
        ),
        IdeaToProductionStep.new(
          metric: metric,
          title: 'Review',
          features: %w[ci_pipelines environments]
        ),
        IdeaToProductionStep.new(
          metric: metric,
          title: 'Staging',
          features: %w[environments deployments]
        ),
        IdeaToProductionStep.new(
          metric: metric,
          title: 'Production',
          features: %w[deployments]
        ),
        IdeaToProductionStep.new(
          metric: metric,
          title: 'Feedback',
          features: %w[projects_prometheus_active service_desk_issues]
        )
      ]
    end

    def average_percentage_score
      cards.sum(&:percentage_score) / cards.size.to_f
    end
  end
end
