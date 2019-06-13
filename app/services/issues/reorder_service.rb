# frozen_string_literal: true

module Issues
  class ReorderService < Issues::BaseService
    def execute(issue)
      return false unless can?(current_user, :update_issue, issue)
      return false if group && !can?(current_user, :read_group, group)

      attrs = issue_params(group)
      return false if attrs.empty?

      update(issue, attrs)
    end

    private

    def group
      return unless params[:group_full_path]

      @group ||= Group.find_by_full_path(params[:group_full_path])
    end

    def update(issue, attrs)
      ::Issues::UpdateService.new(project, current_user, attrs).execute(issue)
    rescue ActiveRecord::RecordNotFound
      false
    end

    def issue_params(group)
      attrs = {}

      if move_between_ids
        attrs[:move_between_ids] = move_between_ids
        attrs[:board_group_id]   = group&.id
      end

      attrs
    end

    def move_between_ids
      return unless params[:move_after_id] || params[:move_before_id]

      @move_between_ids ||= [params[:move_after_id].to_i, params[:move_before_id].to_i].map { |m| m.positive? ? m : nil }
    end
  end
end
