# frozen_string_literal: true

module Projects
  class ProjectNotificationFacade
    include ActiveModel::API

    attr_accessor :project

    def call(old_path_with_namespace)
      NotificationService.new.project_was_moved(project, old_path_with_namespace)
    end
  end
end
