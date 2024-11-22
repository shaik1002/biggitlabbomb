# frozen_string_literal: true

module IssuableCollectionsAction
  extend ActiveSupport::Concern
  include IssuableCollections
  include IssuesCalendar

  included do
    before_action :check_search_rate_limit!, only: [:issues, :merge_requests, :search_merge_requests], if: -> {
      params[:search].present?
    }
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def issues
    @issues = issuables_collection
              .non_archived
              .page(params[:page])

    @issuable_meta_data = Gitlab::IssuableMetadata.new(current_user, @issues).data

    respond_to do |format|
      format.html do
        # TODO: Check if this action is used for anything other than /dashboard/issues
        # TODO: To feature flag this, just return and keep Rails magic working :/

        render inertia: 'Issues/Index', props: {
          breadcrumbs: [
            { text: _('Your work'), href: root_url },
            { text: _('Issues'), href: issues_dashboard_path }
          ],
          issues: helpers.dashboard_issues_list_data(current_user)
        }
      end
      format.atom { render layout: 'xml' }
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def merge_requests
    respond_to do |format|
      format.html do
        render inertia: 'MergeRequests/Index', props: {
          initialData: helpers.merge_request_dashboard_data,
          breadcrumbs: [
            { text: _('Your work'), href: root_url },
            { text: _('Merge requests'), href: merge_requests_dashboard_path }
          ]
        }
      end
    end
  end

  def issues_calendar
    render_issues_calendar(issuables_collection)
  end

  private

  def sorting_field
    case action_name
    when 'issues'
      Issue::SORTING_PREFERENCE_FIELD
    when 'merge_requests', 'search_merge_requests'
      MergeRequest::SORTING_PREFERENCE_FIELD
    end
  end

  def finder_type
    case action_name
    when 'issues', 'issues_calendar'
      IssuesFinder
    when 'merge_requests', 'search_merge_requests'
      MergeRequestsFinder
    end
  end

  def finder_options
    issue_types = Issue::TYPES_FOR_LIST

    super.merge(
      non_archived: true,
      issue_types: issue_types
    )
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def render_merge_requests
    @merge_requests = issuables_collection.page(params[:page])

    @issuable_meta_data = Gitlab::IssuableMetadata.new(current_user, @merge_requests).data
  rescue ActiveRecord::QueryCanceled => exception # rubocop:disable Database/RescueQueryCanceled
    log_exception(exception)

    @search_timeout_occurred = true
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables
end
