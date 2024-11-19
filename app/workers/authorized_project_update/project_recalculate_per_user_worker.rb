# frozen_string_literal: true

module AuthorizedProjectUpdate
  class ProjectRecalculatePerUserWorker < ProjectRecalculateWorker
    data_consistency :always

    feature_category :permissions
    urgency :high
    queue_namespace :authorized_project_update

    deduplicate :until_executing, including_scheduled: true
    idempotent!

    def perform(project_id, user_id)
      project = Project.find_by_id(project_id)
      user = User.find_by_id(user_id)

      return unless project && user

      in_lock(lock_key(project, user), ttl: 10.seconds) do
        AuthorizedProjectUpdate::ProjectRecalculatePerUserService.new(project, user).execute
      end
    end

    private

    def lock_key(project, user)
      "authorized_project_update/project_recalculate_worker/project/#{project.id}/user/#{user.id}"
    end
  end
end
