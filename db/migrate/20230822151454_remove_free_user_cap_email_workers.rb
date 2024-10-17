# frozen_string_literal: true

class RemoveFreeUserCapEmailWorkers < Gitlab::Database::Migration[2.1]
  DEPRECATED_JOB_CLASSES = %w[
    Namespaces::FreeUserCap::BackfillNotificationClearingJobsWorker
    Namespaces::FreeUserCap::BackfillNotificationJobsWorker
    Namespaces::FreeUserCap::NotificationClearingWorker
    Namespaces::FreeUserCap::OverLimitNotificationWorker
  ]
  disable_ddl_transaction!
  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end
