# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Configuration
        module Structure
          autoload :Base, 'gitlab/backup/cli/configuration/structure/base'
          autoload :Field, 'gitlab/backup/cli/configuration/structure/field'
          autoload :FieldDefinitions, 'gitlab/backup/cli/configuration/structure/field_definitions'

          def self.included(target)
            target.include(::ActiveModel::Model)
            target.include(FieldDefinitions)

            super
          end
        end
      end
    end
  end
end
