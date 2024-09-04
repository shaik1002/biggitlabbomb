# frozen_string_literal: true

module Projects
  module Settings
    class PackagesAndRegistriesController < Projects::ApplicationController
      layout 'project_settings'

      before_action :authorize_admin_project!
      before_action :packages_and_registries_settings_enabled!
      before_action :set_feature_flag_packages_protected_packages, only: :show
      before_action :set_feature_flag_container_registry_protected_containers, only: :show
      before_action :load_dependency_firewall_setting

      feature_category :package_registry
      urgency :low

      def show
      end

      def update
        @dependency_firewall_setting.update!(dependency_firewall_setting_params)

        redirect_to(action: :show)
      end

      def cleanup_tags
        registry_settings_enabled!

        @hide_search_settings = true
      end

      private

      def load_dependency_firewall_setting
        @dependency_firewall_setting = ::Packages::DependencyFirewall::Setting.find_or_initialize_for_project(@project)
      end

      def dependency_firewall_setting_params
        params.require(:packages_dependency_firewall_setting).permit(
          :deny_regex_check_enabled,
          :deny_regex_check_list,
          :deny_regex_check_quarantine,
          :deny_regex_check_create_issue,
          :dependency_scanning_check_enabled,
          :dependency_scanning_check_threshold,
          :dependency_scanning_check_quarantine,
          :dependency_scanning_check_create_issue,
          :owasp_dep_scan_check_enabled,
          :owasp_dep_scan_check_quarantine,
          :owasp_dep_scan_check_create_issue
        )
      end

      def packages_and_registries_settings_enabled!
        render_404 unless can?(current_user, :view_package_registry_project_settings, project)
      end

      def registry_settings_enabled!
        render_404 unless Gitlab.config.registry.enabled &&
          can?(current_user, :admin_container_image, project)
      end

      def set_feature_flag_packages_protected_packages
        push_frontend_feature_flag(:packages_protected_packages, project)
      end

      def set_feature_flag_container_registry_protected_containers
        push_frontend_feature_flag(:container_registry_protected_containers, project)
      end
    end
  end
end
