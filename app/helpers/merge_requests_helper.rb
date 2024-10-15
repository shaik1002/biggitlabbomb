# frozen_string_literal: true

module MergeRequestsHelper
  include Gitlab::Utils::StrongMemoize
  include CompareHelper
  DIFF_BATCH_ENDPOINT_PER_PAGE = 5

  def create_mr_button_from_event?(event)
    create_mr_button?(from: event.branch_name, source_project: event.project)
  end

  def create_mr_path_from_push_event(event)
    create_mr_path(from: event.branch_name, source_project: event.project)
  end

  def mr_css_classes(mr)
    classes = ["merge-request"]
    classes << "closed" if mr.closed?
    classes << "merged" if mr.merged?
    classes.join(' ')
  end

  def merge_path_description(merge_request, with_arrow: false)
    if merge_request.for_fork?
      msg = if with_arrow
              _("Project:Branches: %{source_project_path}:%{source_branch} → %{target_project_path}:%{target_branch}")
            else
              _("Project:Branches: %{source_project_path}:%{source_branch} to %{target_project_path}:%{target_branch}")
            end

      msg % {
        source_project_path: merge_request.source_project_path,
        source_branch: merge_request.source_branch,
        target_project_path: merge_request.target_project.full_path,
        target_branch: merge_request.target_branch
      }
    else
      msg = if with_arrow
              _("Branches: %{source_branch} → %{target_branch}")
            else
              _("Branches: %{source_branch} to %{target_branch}")
            end

      msg % {
        source_branch: merge_request.source_branch,
        target_branch: merge_request.target_branch
      }
    end
  end

  def mr_change_branches_path(merge_request)
    project_new_merge_request_path(
      @project,
      merge_request: {
        source_project_id: merge_request.source_project_id,
        target_project_id: merge_request.target_project_id,
        source_branch: merge_request.source_branch,
        target_branch: merge_request.target_branch
      },
      change_branches: true
    )
  end

  def format_mr_branch_names(merge_request)
    source_path = merge_request.source_project_path
    target_path = merge_request.target_project_path
    source_branch = merge_request.source_branch
    target_branch = merge_request.target_branch

    if source_path == target_path
      [source_branch, target_branch]
    else
      ["#{source_path}:#{source_branch}", "#{target_path}:#{target_branch}"]
    end
  end

  def target_projects(project)
    MergeRequestTargetProjectFinder.new(current_user: current_user, source_project: project)
      .execute(include_routes: true)
  end

  def merge_request_button_hidden?(merge_request, closed)
    merge_request.closed? == closed || (merge_request.merged? == closed && !merge_request.closed?) || merge_request.closed_or_merged_without_fork?
  end

  def merge_request_version_path(project, merge_request, merge_request_diff, start_sha = nil)
    diffs_project_merge_request_path(project, merge_request, diff_id: merge_request_diff.id, start_sha: start_sha)
  end

  def merge_params(merge_request)
    {
      auto_merge_strategy: AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS,
      should_remove_source_branch: true,
      sha: merge_request.diff_head_sha,
      squash: merge_request.squash_on_merge?
    }
  end

  def tab_link_for(merge_request, tab, options = {}, &block)
    data_attrs = {
      action: tab.to_s,
      target: "##{tab}",
      toggle: options.fetch(:force_link, false) ? '' : 'tabvue'
    }

    url = case tab
          when :show
            data_attrs[:target] = '#notes'
            method(:project_merge_request_path)
          when :commits
            method(:commits_project_merge_request_path)
          when :pipelines
            method(:pipelines_project_merge_request_path)
          when :diffs
            method(:diffs_project_merge_request_path)
          else
            raise "Cannot create tab #{tab}."
          end

    link_to(url[merge_request.project, merge_request], data: data_attrs, &block)
  end

  def allow_collaboration_unavailable_reason(merge_request)
    return if merge_request.can_allow_collaboration?(current_user)

    minimum_visibility = [merge_request.target_project.visibility_level,
                          merge_request.source_project.visibility_level].min

    if minimum_visibility < Gitlab::VisibilityLevel::INTERNAL
      _('Not available for private projects')
    elsif ProtectedBranch.protected?(merge_request.source_project, merge_request.source_branch)
      _('Not available for protected branches')
    elsif !merge_request.author.can?(:push_code, merge_request.source_project)
      _('Merge request author cannot push to target project')
    end
  end

  def merge_request_source_project_for_project(project = @project)
    unless can?(current_user, :create_merge_request_in, project)
      return
    end

    if can?(current_user, :create_merge_request_from, project)
      project
    else
      current_user.fork_of(project)
    end
  end

  def user_merge_requests_counts
    @user_merge_requests_counts ||= begin
      assigned_count = assigned_issuables_count(:merge_requests)
      review_requested_count = review_requested_merge_requests_count
      total_count = assigned_count + review_requested_count

      {
        assigned: assigned_count,
        review_requested: review_requested_count,
        total: total_count
      }
    end
  end

  def reviewers_label(merge_request, include_value: true)
    reviewers = merge_request.reviewers

    if include_value
      sanitized_list = sanitize_name(reviewers.map(&:name).to_sentence)
      ns_('NotificationEmail|Reviewer: %{users}', 'NotificationEmail|Reviewers: %{users}', reviewers.count) % { users: sanitized_list }
    else
      ns_('NotificationEmail|Reviewer', 'NotificationEmail|Reviewers', reviewers.count)
    end
  end

  def notifications_todos_buttons_enabled?
    Feature.enabled?(:notifications_todos_buttons, current_user)
  end

  def diffs_tab_pane_data(project, merge_request, params)
    {
      "is-locked": merge_request.discussion_locked?,
      endpoint: diffs_project_merge_request_path(project, merge_request, 'json', params),
      endpoint_metadata: @endpoint_metadata_url,
      endpoint_batch: diffs_batch_project_json_merge_request_path(project, merge_request, 'json', params),
      endpoint_coverage: @coverage_path,
      endpoint_diff_for_path: diff_for_path_namespace_project_merge_request_path(format: 'json', id: merge_request.iid, namespace_id: project.namespace.to_param, project_id: project.path),
      help_page_path: help_page_path('user/project/merge_requests/reviews/suggestions'),
      current_user_data: @current_user_data,
      update_current_user_path: @update_current_user_path,
      project_path: project_path(merge_request.project),
      changes_empty_state_illustration: image_path('illustrations/empty-state/empty-commit-md.svg'),
      is_fluid_layout: fluid_layout.to_s,
      dismiss_endpoint: callouts_path,
      show_suggest_popover: show_suggest_popover?.to_s,
      show_whitespace_default: @show_whitespace_default.to_s,
      file_by_file_default: @file_by_file_default.to_s,
      default_suggestion_commit_message: default_suggestion_commit_message(project),
      source_project_default_url: merge_request.source_project && default_url_to_repo(merge_request.source_project),
      source_project_full_path: merge_request.source_project&.full_path,
      is_forked: project.forked?.to_s,
      new_comment_template_paths: new_comment_template_paths(project.group, project).to_json,
      iid: merge_request.iid,
      per_page: DIFF_BATCH_ENDPOINT_PER_PAGE,
      pinned_file_url: @pinned_file_url
    }
  end

  def award_emoji_merge_request_api_path(merge_request)
    api_v4_projects_merge_requests_award_emoji_path(id: merge_request.project.id, merge_request_iid: merge_request.iid)
  end

  def how_merge_modal_data(merge_request)
    {
      is_fork: merge_request.for_fork?.to_s,
      can_merge: merge_request.can_be_merged_by?(current_user).to_s,
      source_branch: merge_request.source_branch,
      source_project_path: merge_request.source_project&.path,
      source_project_full_path: merge_request.source_project&.full_path,
      source_project_default_url: merge_request.source_project && default_url_to_repo(merge_request.source_project),
      target_branch: merge_request.target_branch,
      reviewing_docs_path: help_page_path('user/project/merge_requests/merge_request_troubleshooting', anchor: "check-out-merge-requests-locally-through-the-head-ref")
    }
  end

  def mr_compare_form_data(_, merge_request)
    {
      source_branch_url: project_new_merge_request_branch_from_path(merge_request.source_project),
      target_branch_url: project_new_merge_request_branch_to_path(merge_request.source_project)
    }
  end

  def project_merge_requests_list_data(project, current_user)
    {
      full_path: project.full_path,
      has_any_merge_requests: project_merge_requests(project).exists?.to_s,
      initial_sort: current_user&.user_preference&.issues_sort,
      is_public_visibility_restricted:
        Gitlab::CurrentSettings.restricted_visibility_levels&.include?(Gitlab::VisibilityLevel::PUBLIC).to_s,
      is_signed_in: current_user.present?.to_s,
      new_merge_request_path: can?(current_user, :create_merge_request_in, project) && project_new_merge_request_path(project),
      show_export_button: "true",
      issuable_type: :merge_request,
      issuable_count: issuables_count_for_state(:merge_request, params[:state]),
      email: current_user.present? ? current_user.notification_email_or_default : nil,
      export_csv_path: export_csv_project_merge_requests_path(project, request.query_parameters),
      rss_url: url_for(safe_params.merge(rss_url_options))
    }
  end

  def project_merge_requests_list_more_actions_data(project, current_user)
    {
      is_signed_in: current_user.present?.to_s,
      issuable_type: :merge_request,
      issuable_count: issuables_count_for_state(:merge_request, params[:state]),
      email: current_user.present? ? current_user.notification_email_or_default : nil,
      export_csv_path: export_csv_project_merge_requests_path(project, request.query_parameters),
      rss_url: url_for(safe_params.merge(rss_url_options))
    }
  end

  private

  def review_requested_merge_requests_count
    current_user.review_requested_open_merge_requests_count
  end

  def default_suggestion_commit_message(project)
    project.suggestion_commit_message.presence || Gitlab::Suggestions::CommitMessage::DEFAULT_SUGGESTION_COMMIT_MESSAGE
  end

  def merge_request_source_branch(merge_request)
    fork_icon = if merge_request.for_fork?
                  title = _('The source project is a fork')
                  content_tag(:span, class: 'gl-align-middle gl-mr-n2 has-tooltip', title: title) do
                    sprite_icon('fork', size: 12, css_class: 'gl-ml-1 has-tooltip')
                  end
                else
                  ''
                end

    branch = if merge_request.for_fork?
               ERB::Util.html_escape(_('%{fork_icon} %{source_project_path}:%{source_branch}')) % { fork_icon: fork_icon.html_safe, source_project_path: merge_request.source_project_path, source_branch: merge_request.source_branch }
             else
               merge_request.source_branch
             end

    branch_title = if merge_request.for_fork?
                     ERB::Util.html_escape(_('%{source_project_path}:%{source_branch}')) % { source_project_path: merge_request.source_project_path, source_branch: merge_request.source_branch }
                   else
                     merge_request.source_branch
                   end

    branch_path = if merge_request.source_project
                    project_tree_path(merge_request.source_project, merge_request.source_branch)
                  else
                    ''
                  end

    link_to branch, branch_path, title: branch_title, class: 'ref-container gl-display-inline-block gl-text-truncate gl-max-w-26 gl-ml-2'
  end

  def merge_request_header(project, merge_request)
    link_to_author = link_to_member(project, merge_request.author, size: 24, extra_class: 'gl-font-weight-bold gl-mr-2', avatar: false)
    copy_action_description = _('Copy branch name')
    copy_action_shortcut = 'b'
    copy_button_title = "#{copy_action_description} <kbd class='flat ml-1' aria-hidden=true>#{copy_action_shortcut}</kbd>"
    copy_button = clipboard_button(text: merge_request.source_branch, title: copy_button_title, aria_keyshortcuts: copy_action_shortcut, aria_label: copy_action_description, class: 'gl-display-none! gl-md-display-inline-block! js-source-branch-copy gl-mx-1')

    target_branch = link_to merge_request.target_branch, project_tree_path(merge_request.target_project, merge_request.target_branch), title: merge_request.target_branch, class: 'ref-container gl-display-inline-block gl-text-truncate gl-max-w-26 gl-mx-2'

    _('%{author} requested to merge %{source_branch} %{copy_button} into %{target_branch} %{created_at}').html_safe % { author: link_to_author.html_safe, source_branch: merge_request_source_branch(merge_request).html_safe, copy_button: copy_button.html_safe, target_branch: target_branch.html_safe, created_at: time_ago_with_tooltip(merge_request.created_at, html_class: 'gl-display-inline-block').html_safe }
  end

  def sticky_header_data(project, merge_request)
    data = {
      iid: merge_request.iid,
      projectPath: project.full_path,
      sourceProjectPath: merge_request.source_project_path,
      title: markdown_field(merge_request, :title),
      isFluidLayout: fluid_layout.to_s,
      blocksMerge: project.only_allow_merge_if_all_discussions_are_resolved?.to_s,
      imported: merge_request.imported?.to_s,
      tabs: [
        ['show', _('Overview'), project_merge_request_path(project, merge_request), merge_request.related_notes.user.count],
        ['commits', _('Commits'), commits_project_merge_request_path(project, merge_request), @commits_count],
        ['diffs', _('Changes'), diffs_project_merge_request_path(project, merge_request), @diffs_count]
      ]
    }

    if project.builds_enabled?
      data[:tabs].insert(2, ['pipelines', _('Pipelines'), pipelines_project_merge_request_path(project, merge_request), @number_of_pipelines])
    end

    data
  end

  def hidden_merge_request_icon(merge_request)
    return unless merge_request.hidden?

    hidden_resource_icon(merge_request)
  end

  def tab_count_display(merge_request, count)
    merge_request.preparing? ? "-" : count
  end

  def review_bar_data(_merge_request, _user)
    { new_comment_template_paths: new_comment_template_paths(@project.group, @project).to_json }
  end

  def merge_request_dashboard_enabled?(current_user)
    current_user.merge_request_dashboard_enabled?
  end

  def merge_request_dashboard_data
    {
      lists: [
        {
          title: _('Open'),
          query: 'assignedMergeRequests',
          variables: {
            reviewerWildcardId: 'NONE'
          }
        },
        {
          title: _('Reviews requested'),
          query: 'reviewRequestedMergeRequests',
          variables: {
            reviewState: 'UNREVIEWED'
          }
        },
        {
          title: _('Returned to you'),
          query: 'assignedMergeRequests',
          variables: {
            reviewStates: %w[REQUESTED_CHANGES REVIEWED]
          }
        },
        {
          title: _('Waiting for reviewers'),
          query: 'assignedMergeRequests',
          variables: {
            reviewState: 'UNREVIEWED'
          }
        },
        {
          title: _('Yours approved'),
          query: 'assignedMergeRequests',
          variables: {
            reviewState: 'APPROVED'
          }
        },
        {
          title: _('Reviewed'),
          query: 'reviewRequestedMergeRequests',
          variables: {
            reviewStates: %w[REQUESTED_CHANGES REVIEWED]
          }
        },
        {
          title: _('Reviews approved'),
          query: 'reviewRequestedMergeRequests',
          variables: {
            reviewState: 'APPROVED'
          }
        },
        {
          title: _('Merged as assignee (1 week ago)'),
          query: 'assignedMergeRequests',
          variables: {
            state: 'merged',
            mergedAfter: 1.week.ago.to_time.iso8601
          }
        },
        {
          title: _('Merged as reviewer (1 week ago)'),
          query: 'reviewRequestedMergeRequests',
          variables: {
            state: 'merged',
            mergedAfter: 1.week.ago.to_time.iso8601
          }
        }

      ]
    }
  end
end

MergeRequestsHelper.prepend_mod_with('MergeRequestsHelper')
