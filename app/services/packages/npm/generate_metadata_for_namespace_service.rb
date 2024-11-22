# frozen_string_literal: true

module Packages
  module Npm
    class GenerateMetadataForNamespaceService < GenerateMetadataService
      def initialize(name, packages, params = {})
        super(name, packages)

        @current_user = params[:current_user]
        @group_or_namespace = params[:group_or_namespace]
      end

      private

      attr_reader :current_user, :group_or_namespace

      def matching_packages
        ::Packages::Package.npm.installable.with_name(name)
      end
      strong_memoize_attr :matching_packages

      def metadata(only_dist_tags)
        matching_packages.each_batch do |batch|
          packages_visible_to_user_in_batch =
            ::Packages::Npm::PackagesForBatchFinder.new(current_user, group_or_namespace, { packages: batch }).execute
          relation = preload_needed_relations(packages_visible_to_user_in_batch, only_dist_tags)

          relation.each do |package|
            build_tags(package)
            store_latest_version(package.version)
            next if only_dist_tags

            build_versions(package)
          end
        end

        {
          name: only_dist_tags ? nil : name,
          versions: versions,
          dist_tags: tags.tap { |t| t['latest'] ||= latest_version }
        }.compact_blank
      end
    end
  end
end
