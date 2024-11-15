# frozen_string_literal: true

module Ci
  class DestroyOldPipelinesWorker
    include ApplicationWorker

    data_consistency :sticky
    feature_category :continuous_integration
    urgency :low
    idempotent!

    LIMIT = 250

    def perform(project_id)
      Project.find_by_id(project_id).try do |project|
        timestamp = project.ci_delete_pipelines_in_seconds.seconds.ago
        pipelines = project.all_pipelines.created_before(timestamp).limit(LIMIT).to_a
        pipelines.each { |pipeline| Ci::InternalDestroyPipelineService.new(pipeline).execute }
      end
    end
  end
end
