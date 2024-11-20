# frozen_string_literal: true

module VsCode
  module Settings
    class VsCodeSetting < ApplicationRecord
      belongs_to :user, inverse_of: :vscode_settings

      validates :settings_context_hash,
        length: { maximum: 255 },
        uniqueness: { scope: [:user_id, :setting_type] }
      validate :settings_context_hash_check

      validates :setting_type, presence: true,
        inclusion: { in: SETTINGS_TYPES },
        uniqueness: { scope: [:user_id, :settings_context_hash] }
      validates :content, :uuid, :version, presence: true

      scope :by_setting_types, ->(setting_types, settings_context_hash = nil) {
        extensions_settings_query = where(setting_type: 'extensions', settings_context_hash: settings_context_hash)
        includes_extensions = setting_types.include?('extensions')

        return extensions_settings_query if setting_types.one? && includes_extensions

        if includes_extensions
          non_extensions_setting_types = setting_types.reject { |setting_type| setting_type == 'extensions' }
          return where(setting_type: non_extensions_setting_types).or(extensions_settings_query)
        end

        where(setting_type: setting_types)
      }
      scope :by_user, ->(user) { where(user: user) }
      scope :by_uuid, ->(uuid) { where(uuid: uuid) }

      private

      def settings_context_hash_check
        return unless setting_type != 'extensions' && settings_context_hash.present?

        errors.add(:settings_context_hash, 'must be blank for non extensions setting type')
      end
    end
  end
end
