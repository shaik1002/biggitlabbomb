# frozen_string_literal: true

module Gitlab
  module Services
    class ProtectionCheckService
      def initialize(project, kind, refs)
        @project = project
        @kind = kind
        @refs = refs
      end

      def protected?
        case @kind.name
        when 'ProtectedBranch'
          protected_branch?
        when 'ProtectedTag'
          protected_tag?
        else
          raise ArgumentError, 'Unsupported protection type'
        end
      end

      private

      def protected_branch?
        ::Projects::ProtectedBranchFacade.new(project: @project).protected?(@refs)
      end

      # TODO: replace me with a facade.
      def protected_tag?
        ProtectedTag.protected?(@project, @refs)
      end
    end
  end
end
