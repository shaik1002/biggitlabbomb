# frozen_string_literal: true

module Gitlab
  module Pages
    VERSION = File.read(Rails.root.join("GITLAB_PAGES_VERSION")).strip.freeze
    INTERNAL_API_REQUEST_HEADER = 'Gitlab-Pages-Api-Request'
    MAX_SIZE = 1.terabyte
    DEPLOYMENT_EXPIRATION = 24.hours

    include JwtAuthenticatable

    class UniqueDomainGenerationFailure < StandardError
      def initialize(msg = "Can't generate unique domain for GitLab Pages")
        super(msg)
      end
    end

    class << self
      def verify_api_request(request_headers)
        decode_jwt(request_headers[INTERNAL_API_REQUEST_HEADER], issuer: 'gitlab-pages')
      rescue JWT::DecodeError
        false
      end

      def secret_path
        Gitlab.config.pages.secret_file
      end

      def access_control_is_forced?
        ::Gitlab.config.pages.access_control &&
          ::Gitlab::CurrentSettings.current_application_settings.force_pages_access_control
      end

      def enabled?
        Gitlab.config.pages.enabled
      end

      def add_unique_domain_to(project)
        return unless enabled?
        # If the project used a unique domain once, it'll always use the same
        return if project.project_setting.pages_unique_domain_in_database.present?

        project.project_setting.pages_unique_domain_enabled = true
        project.project_setting.pages_unique_domain = generate_unique_domain(project)
      end

      def multiple_versions_enabled_for?(project)
        return false if project.blank?

        ::Feature.enabled?(:pages_multiple_versions_setting, project) &&
          project.licensed_feature_available?(:pages_multiple_versions) &&
          project.project_setting.pages_multiple_versions_enabled
      end

      private

      def generate_unique_domain(project)
        10.times do
          pages_unique_domain = Gitlab::Pages::RandomDomain.generate(project_path: project.path)
          return pages_unique_domain unless ProjectSetting.unique_domain_exists?(pages_unique_domain)
        end

        raise UniqueDomainGenerationFailure
      end
    end
  end
end
