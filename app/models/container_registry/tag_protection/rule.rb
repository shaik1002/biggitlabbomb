# frozen_string_literal: true

module ContainerRegistry
  module TagProtection
    class Rule < ApplicationRecord
      self.table_name = 'container_registry_tag_protection_rules'

      ACCESS_LEVELS = Gitlab::Access.sym_options_with_admin.slice(:maintainer, :owner, :admin).freeze

      enum :minimum_access_level_for_delete, ACCESS_LEVELS, prefix: true
      enum :minimum_access_level_for_push, ACCESS_LEVELS, prefix: true

      belongs_to :project, inverse_of: :container_registry_tag_protection_rules

      validates :minimum_access_level_for_delete, :minimum_access_level_for_push, presence: true
      validates :tag_name_pattern, presence: true, uniqueness: { scope: :project_id }, length: { maximum: 100 }
      validates :tag_name_pattern,
        format: {
          with:
            Gitlab::Regex::ContainerRegistry::TagProtection::Rules.protection_rules_tag_name_pattern_regex,
          message:
            ->(_object, _data) { _('should be a valid image tag name with optional wildcard characters.') }
        }
    end
  end
end
