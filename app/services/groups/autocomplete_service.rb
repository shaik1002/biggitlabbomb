# frozen_string_literal: true

module Groups
  class AutocompleteService < Groups::BaseService
    include LabelsAsHash

    # rubocop: disable CodeReuse/ActiveRecord
    def issues(confidential_only: false, issue_types: nil)
      finder_params = { group_id: group.id, state: 'opened' }
      finder_params[:confidential] = true if confidential_only.present?
      finder_params[:issue_types] = issue_types if issue_types.present?

      finder_class =
        if show_namespace_level_work_items?
          finder_params[:include_descendants] = true
          WorkItems::WorkItemsFinder
        else
          finder_params[:include_subgroups] = true
          IssuesFinder
        end

      finder_class.new(current_user, finder_params)
                  .execute
                  .preload(project: :namespace)
                  .with_work_item_type
                  .select(:iid, :title, :project_id, :namespace_id, 'work_item_types.icon_name')
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def merge_requests
      MergeRequestsFinder.new(current_user, group_id: group.id, include_subgroups: true, state: 'opened')
        .execute
        .preload(target_project: :namespace)
        .select(:iid, :title, :target_project_id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def milestones
      group_ids = group.self_and_ancestors.public_or_visible_to_user(current_user).pluck(:id)

      MilestonesFinder.new(group_ids: group_ids).execute.select(:iid, :title, :due_date)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def labels_as_hash(target)
      super(target, group_id: group.id, only_group_labels: true, include_ancestor_groups: true)
    end

    def commands(noteable)
      return [] unless noteable

      QuickActions::InterpretService.new(container: group, current_user: current_user).available_commands(noteable)
    end

    def show_namespace_level_work_items?
      ::Feature.enabled?(:namespace_level_work_items, group) &&
        ::Feature.enabled?(:cache_autocomplete_sources_issues, group, type: :wip)
    end
  end
end

Groups::AutocompleteService.prepend_mod
