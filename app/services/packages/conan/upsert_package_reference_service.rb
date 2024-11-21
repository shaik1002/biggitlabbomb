# frozen_string_literal: true

module Packages
  module Conan
    class UpsertPackageReferenceService
      include Gitlab::Utils::StrongMemoize

      def initialize(package, package_reference_value)
        @package = package
        @package_reference_value = package_reference_value
      end

      def execute!
        package_reference.validate!

        ServiceResponse.success(payload: upsert_package_reference[0]['id'])
      rescue ActiveRecord::RecordInvalid => exception
        if exception.message.include?('has already been taken')
          return ServiceResponse.success(payload: existing_package_reference_id)
        end

        raise
      end

      private

      attr_reader :package, :package_reference_value

      def package_reference
        ::Packages::Conan::PackageReference.new(
          package_id: package.id,
          reference: package_reference_value,
          project_id: package.project_id
        )
      end
      strong_memoize_attr :package_reference

      def existing_package_reference_id
        ::Packages::Conan::PackageReference
          .find_by_package_id_and_reference(package.id, package_reference_value).pluck_primary_key.first
      end

      def upsert_package_reference
        ::Packages::Conan::PackageReference
          .upsert(
            package_reference.attributes.slice('package_id', 'project_id', 'reference'),
            unique_by: %i[package_id reference]
          )
      end
    end
  end
end
