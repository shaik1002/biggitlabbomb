# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class Description < Base
        def before_create
          return unless target_work_item.get_widget(:description)

          description_params = MarkdownContentRewriterService.new(
            current_user,
            work_item,
            :description,
            work_item.namespace,
            target_work_item.namespace
          ).execute

          # The service returns `description`, `description_html` and also `skip_markdown_cache_validation`.
          # We need to assign all of those attributes to the target work item.
          target_work_item.assign_attributes(description_params)
        end

        def post_move_cleanup
          # It is a field in the work_item record, it will be removed upon the work_item deletion
        end
      end
    end
  end
end
