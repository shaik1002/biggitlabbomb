# frozen_string_literal: true

module AuthorizedProjectUpdate
  class PeriodicRecalculateWorker
    include ApplicationWorker

    # This worker does not perform work scoped to a context
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    data_consistency :sticky, feature_flag: :change_data_consistency_sticky_for_permissions_workers

    feature_category :permissions
    urgency :low

    idempotent!

    def perform
      AuthorizedProjectUpdate::PeriodicRecalculateService.new.execute
    end
  end
end
