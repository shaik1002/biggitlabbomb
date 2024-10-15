# frozen_string_literal: true

module Packages
  module TerraformModule
    class CreatePackageService < ::Packages::CreatePackageService
      include Gitlab::Utils::StrongMemoize

      def execute
        if params[:module_version].blank?
          return ServiceResponse.error(message: 'Version is empty.', reason: :bad_request)
        end

        if duplicates_not_allowed? && current_package_exists_elsewhere?
          return ServiceResponse.error(
            message: 'A package with the same name already exists in the namespace',
            reason: :forbidden
          )
        end

        if current_package_version_exists?
          return ServiceResponse.error(message: 'Package version already exists.', reason: :forbidden)
        end

        package, package_file = ApplicationRecord.transaction { create_terraform_module_package! }

        if Feature.enabled?(:index_terraform_module_archive, project)
          ::Packages::TerraformModule::ProcessPackageFileWorker.perform_async(package_file.id)
        end

        ServiceResponse.success(payload: { package: package })
      rescue ActiveRecord::RecordInvalid => e
        ServiceResponse.error(message: e.message, reason: :unprocessable_entity)
      end

      private

      def create_terraform_module_package!
        package = create_package!(:terraform_module, name: name, version: params[:module_version])
        package_file = ::Packages::CreatePackageFileService.new(package, file_params).execute
        [package, package_file]
      end

      def duplicates_not_allowed?
        return true if package_settings_with_duplicates_allowed.blank?

        package_settings_with_duplicates_allowed.none? do |setting|
          setting.terraform_module_duplicates_allowed ||
            ::Gitlab::UntrustedRegexp.new("\\A#{setting.terraform_module_duplicate_exception_regex}\\z").match?(name)
        end
      end

      def current_package_exists_elsewhere?
        ::Packages::Package
          .for_projects(project.root_namespace.all_projects.id_not_in(project.id))
          .with_package_type(:terraform_module)
          .with_name(name)
          .not_pending_destruction
          .exists?
      end

      def current_package_version_exists?
        project.packages
          .with_package_type(:terraform_module)
          .with_name(name)
          .with_version(params[:module_version])
          .not_pending_destruction
          .exists?
      end

      def name
        "#{params[:module_name]}/#{params[:module_system]}"
      end
      strong_memoize_attr :name

      def file_name
        "#{params[:module_name]}-#{params[:module_system]}-#{params[:module_version]}.tgz"
      end
      strong_memoize_attr :file_name

      def file_params
        {
          file: params[:file],
          size: params[:file].size,
          file_sha256: params[:file].sha256,
          file_name: file_name,
          build: params[:build]
        }
      end

      def package_settings_with_duplicates_allowed
        ::Namespace::PackageSetting
          .select(:terraform_module_duplicates_allowed, :terraform_module_duplicate_exception_regex)
          .namespace_id_in(project.namespace.self_and_ancestor_ids)
          .with_terraform_module_duplicates_allowed_or_exception_regex
      end
      strong_memoize_attr :package_settings_with_duplicates_allowed
    end
  end
end
