# frozen_string_literal: true

module Gitlab
  module Regex
    module ContainerRegistry
      module TagProtection
        module Rules
          def self.protection_rules_tag_name_pattern_regex
            @protection_rules_tag_name_pattern_regex ||= Gitlab::Regex.container_repository_tag_name_regex
          end
        end
      end
    end
  end
end
