# frozen_string_literal: true

module Types
  module Ci
    module Catalog
      module Resources
        # rubocop: disable Graphql/AuthorizeTypes -- Authorization is handled by VersionType
        class ComponentType < BaseObject
          graphql_name 'CiCatalogResourceComponent'

          field :id, ::Types::GlobalIDType[::Ci::Catalog::Resources::Component], null: false,
            description: 'ID of the component.'

          field :name, GraphQL::Types::String, null: true,
            description: 'Name of the component.'

          field :include_path, GraphQL::Types::String, null: true,
            description: 'Path used to include the component.'

          field :inputs, [Types::Ci::Catalog::Resources::Components::InputType], null: true,
            description: 'Inputs for the component.'

          def inputs
            spec_inputs = object.spec.fetch('inputs', {})

            spec_inputs.map do |key, value|
              {
                name: key,
                required: !value&.key?('default'),
                default: value&.dig('default')
              }
            end
          end
        end
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
