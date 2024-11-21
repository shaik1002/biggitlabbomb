# frozen_string_literal: true

module Projects
  class ProtectDefaultBranchFacade
    include ActiveModel::API

    attr_accessor :project

    def call
      Projects::ProtectDefaultBranchService
        .new(project)
        .execute
    end
  end
end
