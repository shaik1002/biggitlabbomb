# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DeleteOrphanedGroups < BatchedMigrationJob
      operation_name :delete_orphaned_group_records
      feature_category :groups_and_projects

      scope_to ->(relation) { relation.where.not(parent_id: nil) }

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
          .joins("LEFT JOIN namespaces AS parent ON namespaces.parent_id = parent.id")
          .where(parent: { id: nil })
          .pluck(:id, :type).each do |orphaned_group_id, type|
            case type
            when ::Group.sti_name
              ::GroupDestroyWorker.perform(orphaned_group_id, admin_bot.id)
            when Namespaces::ProjectNamespace.sti_name
              ::Namespaces::ProjectNamespace.delete(orphaned_group_id)
            end
          end
        end
      end

      private

      def admin_bot
        @_admin_bot ||= Users::Internal.admin_bot
      end
    end
  end
end
