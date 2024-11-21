# frozen_string_literal: true

module Projects
  class ProtectedBranchFacade
    include ActiveModel::API
    include ::Integrations::BranchProtectionLogic

    attr_accessor :project

    def protected?(ref_name)
      protected_branch?(ref_name)
    end
  end
end
