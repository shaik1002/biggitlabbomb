# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class FanOutMigratePermanentlyDisabledWebhookIntoTemporarilyDisabled < BatchedMigrationJob
      operation_name :fan_out_migrate_permanently_disabled_webhook_into_temporarily_disabled
      scope_to ->(relation) { relation.where('recent_failures > 3').where(disabled_until: nil) }
      feature_category :integrations

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.update_all(
            disabled_until: Time.current + rand(1..10).minutes,
            backoff_count: ::WebHooks::AutoDisabling::MAX_FAILURES
          )
        end
      end
    end
  end
end
