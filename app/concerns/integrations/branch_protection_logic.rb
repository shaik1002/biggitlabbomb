# frozen_string_literal: true

module Integrations
  module BranchProtectionLogic
    extend ActiveSupport::Concern

    included do
      def cache_service
        @cache_service ||= ProtectedBranches::CacheService.new(project)
      end
    end

    def protected_branch?(ref_name)
      return true if project.empty_repo? && project.default_branch_protected?
      return false if ref_name.blank?

      cache_service.fetch(ref_name) do
        branch_protected?(ref_name)
      end
    end

    private

    def branch_protected?(ref_name)
      ProtectedBranch.matching(ref_name, protected_refs: protected_refs).present?
    end

    def protected_refs
      project.all_protected_branches
    end
  end
end
