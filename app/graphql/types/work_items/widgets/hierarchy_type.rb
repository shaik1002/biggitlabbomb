# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes
      class HierarchyType < BaseObject
        graphql_name 'WorkItemWidgetHierarchy'
        description 'Represents a hierarchy widget'

        implements Types::WorkItems::WidgetInterface

        field :parent, ::Types::WorkItemType,
          null: true, complexity: 5,
          description: 'Parent work item.'

        field :children, ::Types::WorkItemType.connection_type,
          null: true, complexity: 5,
          description: 'Child work items.'

        field :has_children, GraphQL::Types::Boolean,
              null: false, description: 'Indicates if the work item has children.'

        # rubocop: disable CodeReuse/ActiveRecord
        def has_children?
          BatchLoader::GraphQL.for(object.work_item.id).batch(default_value: false) do |ids, loader|
            links_for_parents = ::WorkItems::ParentLink.for_parents(ids)
                                           .select(:work_item_parent_id)
                                           .group(:work_item_parent_id)
                                           .reorder(nil)

            links_for_parents.each { |link| loader.call(link.work_item_parent_id, true) }
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        alias_method :has_children, :has_children?

        def children
          object.children.inc_relations_for_permission_check
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
