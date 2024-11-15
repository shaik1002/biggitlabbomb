# frozen_string_literal: true

module Ci
  class InternalDestroyPipelineService
    attr_reader :pipeline

    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute
      Ci::ExpirePipelineCacheService.new.execute(pipeline, delete: true)

      # ensure cancellation happens sync so we accumulate compute minutes successfully
      # before deleting the pipeline.
      ::Ci::CancelPipelineService.new(
        pipeline: pipeline,
        current_user: nil,
        cascade_to_children: true,
        execute_async: false).force_execute

      # The pipeline, the builds, job and pipeline artifacts all get destroyed here.
      # Ci::Pipeline#destroy triggers fast destroy on job_artifacts and
      # build_trace_chunks to remove the records and data stored in object storage.
      # ci_builds records are deleted using ON DELETE CASCADE from ci_pipelines
      #
      pipeline.reset.destroy!

      ServiceResponse.success(message: 'Pipeline not found')
    rescue ActiveRecord::RecordNotFound
      ServiceResponse.error(message: 'Pipeline not found')
    end
  end
end
