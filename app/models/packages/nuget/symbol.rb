# frozen_string_literal: true

module Packages
  module Nuget
    class Symbol < ApplicationRecord
      include FileStoreMounter
      include ShaAttribute
      include Packages::Destructible
      include UpdateProjectStatistics

      # Used in destroying orphan symbols in worker
      enum :status, default: 0, processing: 1, error: 3

      belongs_to :package, class_name: 'Packages::Nuget::Package', inverse_of: :nuget_symbols
      belongs_to :project

      update_project_statistics project_statistics_name: :packages_size

      validates :file, :file_path, :signature, :object_storage_key, :size, presence: true
      validates :signature, uniqueness: { scope: %i[file_path package_id] }, if: -> { package }
      validates :object_storage_key, uniqueness: true
      validates :package, presence: true

      sha256_attribute :file_sha256

      mount_file_store_uploader SymbolUploader

      before_validation :set_object_storage_key, on: :create

      scope :orphan, -> { where(package_id: nil) }
      scope :pending_destruction, -> { orphan.default }
      scope :with_file_name, ->(file_name) { where(arel_table[:file].lower.eq(file_name.downcase)) }
      scope :with_signature, ->(signature) { where(arel_table[:signature].lower.eq(signature.downcase)) }
      scope :with_file_sha256, ->(checksums) { where(file_sha256: Array.wrap(checksums).map(&:downcase)) }

      def self.find_by_signature_and_file_and_checksum(signature, file_name, checksums)
        with_signature(signature)
        .with_file_name(file_name)
        .with_file_sha256(checksums)
        .where.not(orphan.where_values_hash)
        .take
      end

      private

      def set_object_storage_key
        return unless project_id && signature

        self.object_storage_key = Gitlab::HashedPath.new(
          'packages', 'nuget', package_id, 'symbols', OpenSSL::Digest::SHA256.hexdigest(signature),
          root_hash: project_id
        ).to_s
      end
    end
  end
end
