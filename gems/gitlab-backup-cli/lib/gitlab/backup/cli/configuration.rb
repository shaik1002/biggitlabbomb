# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Configuration
        autoload :ConfigurationBase, 'gitlab/backup/cli/configuration/configuration_base'
        autoload :DatabasesConfiguration, 'gitlab/backup/cli/configuration/databases_configuration'
        autoload :FieldDefinitions, 'gitlab/backup/cli/configuration/field_definitions'
        autoload :Main, 'gitlab/backup/cli/configuration/main'
        autoload :ObjectsConfiguration, 'gitlab/backup/cli/configuration/objects_configuration'
        autoload :RepositoriesConfiguration, 'gitlab/backup/cli/configuration/repositories_configuration'
        autoload :Structure, 'gitlab/backup/cli/configuration/structure'
        autoload :TypeCasting, 'gitlab/backup/cli/configuration/type_casting'
      end
    end
  end
end
