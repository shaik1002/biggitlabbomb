# frozen_string_literal: true

module Mutations
  module WorkItems
    class Create < BaseMutation
      graphql_name 'WorkItemCreate'

      include Mutations::SpamProtection
      include FindsNamespace
      include Mutations::WorkItems::Widgetable

      description "Creates a work item."

      authorize :create_work_item

      MUTUALLY_EXCLUSIVE_ARGUMENTS_ERROR = 'Please provide either projectPath or namespacePath argument, but not both.'
      DISABLED_FF_ERROR = 'namespace_level_work_items feature flag is disabled. Only project paths allowed.'

      argument :assignees_widget, ::Types::WorkItems::Widgets::AssigneesInputType,
               required: false,
               description: 'Input for assignees widget.'
      argument :confidential, GraphQL::Types::Boolean,
               required: false,
               description: 'Sets the work item confidentiality.'
      argument :description, GraphQL::Types::String,
               required: false,
               description: copy_field_description(Types::WorkItemType, :description),
               deprecated: { milestone: '16.9', reason: 'use description widget instead' }
      argument :description_widget, ::Types::WorkItems::Widgets::DescriptionInputType,
               required: false,
               description: 'Input for description widget.'
      argument :hierarchy_widget, ::Types::WorkItems::Widgets::HierarchyCreateInputType,
               required: false,
               description: 'Input for hierarchy widget.'
      argument :labels_widget, ::Types::WorkItems::Widgets::LabelsCreateInputType,
               required: false,
               description: 'Input for labels widget.'
      argument :milestone_widget, ::Types::WorkItems::Widgets::MilestoneInputType,
               required: false,
               description: 'Input for milestone widget.'
      argument :namespace_path, GraphQL::Types::ID,
               required: false,
               description: 'Full path of the namespace(project or group) the work item is created in.'
      argument :project_path, GraphQL::Types::ID,
               required: false,
               description: 'Full path of the project the work item is associated with.',
               deprecated: {
                 reason: 'Please use namespace_path instead. That will cover for both projects and groups',
                 milestone: '15.10'
               }
      argument :title, GraphQL::Types::String,
               required: true,
               description: copy_field_description(Types::WorkItemType, :title)
      argument :work_item_type_id, ::Types::GlobalIDType[::WorkItems::Type],
               required: true,
               description: 'Global ID of a work item type.'

      field :work_item, Types::WorkItemType,
            null: true,
            description: 'Created work item.'

      def ready?(**args)
        if args.slice(:project_path, :namespace_path)&.length != 1
          raise Gitlab::Graphql::Errors::ArgumentError, MUTUALLY_EXCLUSIVE_ARGUMENTS_ERROR
        end

        super
      end

      def resolve(project_path: nil, namespace_path: nil, **attributes)
        container_path = project_path || namespace_path
        container = authorized_find!(container_path)
        check_feature_available!(container)

        params = global_id_compatibility_params(attributes).merge(author_id: current_user.id)
        type = ::WorkItems::Type.find(attributes[:work_item_type_id])
        widget_params = extract_widget_params!(type, params, container)

        create_result = ::WorkItems::CreateService.new(
          container: container,
          current_user: current_user,
          params: params,
          widget_params: widget_params
        ).execute

        check_spam_action_response!(create_result[:work_item]) if create_result[:work_item]

        {
          work_item: create_result.success? ? create_result[:work_item] : nil,
          errors: create_result.errors
        }
      end

      private

      def check_feature_available!(container)
        return unless container.is_a?(::Group) && Feature.disabled?(:namespace_level_work_items, container)

        raise Gitlab::Graphql::Errors::ArgumentError, DISABLED_FF_ERROR
      end

      def global_id_compatibility_params(params)
        params[:work_item_type_id] = params[:work_item_type_id]&.model_id

        params
      end
    end
  end
end

Mutations::WorkItems::Create.prepend_mod
