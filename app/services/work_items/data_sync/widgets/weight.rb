# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class Weight < Base
        def before_create
          return unless target_work_item.get_widget(:weight)

          target_work_item.weight = work_item.weight
        end

        def post_move_cleanup
          # It is a field in the work_item record, it will be removed upon the work_item deletion
        end
      end
    end
  end
end
