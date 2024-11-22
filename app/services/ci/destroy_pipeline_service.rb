# frozen_string_literal: true

module Ci
  class DestroyPipelineService < BaseService
    def execute(pipeline)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :destroy_pipeline, pipeline)

      Ci::InternalDestroyPipelineService.new(pipeline).execute
    end
  end
end

Ci::DestroyPipelineService.prepend_mod
