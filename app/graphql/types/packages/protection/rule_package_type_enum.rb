# frozen_string_literal: true

module Types
  module Packages
    module Protection
      class RulePackageTypeEnum < BaseEnum
        graphql_name 'PackagesProtectionRulePackageType'
        description 'Package type of a package protection rule resource'

        value 'NPM',
          value: 'npm',
          description: 'Packages of the npm format.'

        value 'PYPI',
          value: 'pypi',
          alpha: { milestone: '17.6' },
          description: "Packages of the PyPI format."
      end
    end
  end
end
