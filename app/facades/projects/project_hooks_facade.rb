# frozen_string_literal: true

module Projects
  class ProjectHooksFacade
    include ActiveModel::API

    attr_accessor :project

    def call(data, hooks_scope = :push_hooks)
      project.triggered_hooks(hooks_scope, data).execute
      SystemHooksService.new.execute_hooks(data, hooks_scope)
    end
  end
end
