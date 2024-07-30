# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class AlterWebhookDeletedAuditEvent < BatchedMigrationJob
      feature_category :webhooks
      scope_to ->(relation) { relation.where(target_type: %w[SystemHook GroupHook ProjectHook]) }
      operation_name :alter_webhook_deleted_audit_event

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.each do |audit_event|
            unless audit_event.target_details.starts_with?("Hook")
              audit_event.update!(target_details: "Hook #{audit_event.details[:target_id]}")
            end
          end
        end
      end
    end
  end
end
