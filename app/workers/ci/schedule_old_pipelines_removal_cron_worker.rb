# frozen_string_literal: true

module Ci
  class ScheduleOldPipelinesRemovalCronWorker
    include ApplicationWorker
    include CronjobQueue

    urgency :low
    idempotent!
    deduplicate :until_executed, including_scheduled: true
    feature_category :continuous_integration
    data_consistency :sticky

    ITERATIONS = 10
    BATCH_SIZE = 100
    LAST_PROCESSED_REDIS_KEY = 'last_processed_project_setting_id_for_old_pipelines_removal'
    REDIS_EXPIRATION_TIME = 2.hours.to_i

    def perform
      return if Feature.disabled?(:ci_delete_old_pipelines, :instance, type: :beta)

      forced_exit = false
      relation = ProjectCiCdSetting
        .id_in(last_processed_id..)
        .configured_to_delete_old_pipelines
        .with_project

      relation.each_batch(of: BATCH_SIZE) do |batch, index|
        enqueue_work(batch, index)
        save_last_processed_id(batch.last.id)

        if index >= ITERATIONS
          forced_exit = true
          break
        end
      end

      remove_last_processed_id unless forced_exit
    end

    def enqueue_work(batch, index)
      Ci::DestroyOldPipelinesWorker.bulk_perform_in_with_contexts(
        3 * index,
        batch,
        arguments_proc: ->(setting) { setting.project_id },
        context_proc: ->(setting) { { project: setting.project } }
      )
    end

    def save_last_processed_id(id)
      with_redis do |redis|
        redis.set(LAST_PROCESSED_REDIS_KEY, id, ex: REDIS_EXPIRATION_TIME)
      end
    end

    def last_processed_id
      with_redis do |redis|
        redis.get(LAST_PROCESSED_REDIS_KEY).to_i
      end
    end

    def remove_last_processed_id
      with_redis do |redis|
        redis.del(LAST_PROCESSED_REDIS_KEY)
      end
    end

    def with_redis(&)
      Gitlab::Redis::SharedState.with(&) # rubocop:disable CodeReuse/ActiveRecord -- not AR
    end
  end
end
