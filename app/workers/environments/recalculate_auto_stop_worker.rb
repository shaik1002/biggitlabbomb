# frozen_string_literal: true

module Environments
  class RecalculateAutoStopWorker
    include ApplicationWorker

    data_consistency :delayed
    idempotent!
    feature_category :environment_management

    def perform(job_id)
      Ci::Processable.find_by_id(job_id).try do |job|
        Environments::RecalculateAutoStopService.new(job).execute
      end
    end
  end
end
