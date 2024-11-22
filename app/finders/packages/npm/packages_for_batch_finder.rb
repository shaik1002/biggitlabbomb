# frozen_string_literal: true

module Packages
  module Npm
    class PackagesForBatchFinder < ::Packages::GroupOrProjectPackageFinder
      extend ::Gitlab::Utils::Override

      def execute
        packages
      end

      private

      def packages
        base.npm.id_in(@params[:packages].map(&:id))
      end

      # TODO: Use packages_visible_to_user
      # packages_visible_to_user(@current_user, within_group: @project_or_group, with_package_registry_enabled: true)
      # https://gitlab.com/gitlab-org/gitlab/-/issues/505645
      override :group_packages
      def group_packages
        return packages_class.none unless Ability.allowed?(@current_user, :read_group, @project_or_group)

        projects = projects_visible_to_reporters.with_package_registry_enabled
        packages_class.for_projects(projects.select(:id)).installable
      end

      def projects_visible_to_reporters
        return @current_user.accessible_projects if @current_user.is_a?(DeployToken)

        Project
          .by_any_overlap_with_traversal_ids(@project_or_group.id)
          .public_or_visible_to_user(@current_user, ::Gitlab::Access::REPORTER)
      end
    end
  end
end
