# frozen_string_literal: true

module ProtectedBranches
  class DestroyService < ProtectedBranches::BaseService
    def execute(protected_branch)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :destroy_protected_branch, protected_branch)

      protected_branch_name = protected_branch.name

      protected_branch.destroy.tap do
        refresh_cache
        after_execute
      end

      ::Gitlab::EventStore.publish(
        ::Repositories::ProtectedBranchDestroyedEvent.new(data: {
          protected_branch_name: protected_branch_name,
          parent_id: project_or_group.id,

          parent_type: if project_or_group.is_a?(Project)
                         ::Repositories::ProtectedBranchDestroyedEvent::PARENT_TYPES[:project]
                       else
                         ::Repositories::ProtectedBranchDestroyedEvent::PARENT_TYPES[:group]
                       end
        })
      )
    end
  end
end

ProtectedBranches::DestroyService.prepend_mod
