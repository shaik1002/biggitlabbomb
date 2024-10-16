# frozen_string_literal: true

module Resolvers
  class MergeRequestsResolver < BaseResolver
    include ResolvesMergeRequests
    extend ::Gitlab::Graphql::NegatableArguments

    type ::Types::MergeRequestType.connection_type, null: true

    alias_method :project, :object

    def self.accept_assignee
      argument :assignee_username, GraphQL::Types::String,
        required: false,
        description: 'Username of the assignee.'
      argument :assignee_wildcard_id, ::Types::AssigneeWildcardIdEnum,
        required: false,
        description: 'Filter by assignee presence. Incompatible with assigneeUsernames and assigneeUsername.'
    end

    def self.accept_author
      argument :author_username, GraphQL::Types::String,
        required: false,
        description: 'Username of the author.'
    end

    def self.accept_reviewer
      argument :reviewer_username, GraphQL::Types::String,
        required: false,
        description: 'Username of the reviewer.'
      argument :reviewer_wildcard_id, ::Types::ReviewerWildcardIdEnum,
        required: false,
        description: 'Filter by reviewer presence. Incompatible with reviewerUsername.'
    end

    argument :iids, [GraphQL::Types::String],
      required: false,
      description: 'Array of IIDs of merge requests, for example `[1, 2]`.'

    argument :source_branches, [GraphQL::Types::String],
      required: false,
      as: :source_branch,
      description: <<~DESC
               Array of source branch names.
               All resolved merge requests will have one of these branches as their source.
      DESC

    argument :target_branches, [GraphQL::Types::String],
      required: false,
      as: :target_branch,
      description: <<~DESC
               Array of target branch names.
               All resolved merge requests will have one of these branches as their target.
      DESC

    argument :state, ::Types::MergeRequestStateEnum,
      required: false,
      description: 'Merge request state. If provided, all resolved merge requests will have the state.'

    argument :draft, GraphQL::Types::Boolean,
      required: false,
      description: 'Limit result to draft merge requests.'

    argument :approved, GraphQL::Types::Boolean,
      required: false,
      description: <<~DESC
               Limit results to approved merge requests.
               Available only when the feature flag `mr_approved_filter` is enabled.
      DESC

    argument :created_after, Types::TimeType,
      required: false,
      description: 'Merge requests created after the timestamp.'
    argument :created_before, Types::TimeType,
      required: false,
      description: 'Merge requests created before the timestamp.'
    argument :deployed_after, Types::TimeType,
      required: false,
      description: 'Merge requests deployed after the timestamp.'
    argument :deployed_before, Types::TimeType,
      required: false,
      description: 'Merge requests deployed before the timestamp.'
    argument :deployment_id, GraphQL::Types::String,
      required: false,
      description: 'ID of the deployment.'
    argument :updated_after, Types::TimeType,
      required: false,
      description: 'Merge requests updated after the timestamp.'
    argument :updated_before, Types::TimeType,
      required: false,
      description: 'Merge requests updated before the timestamp.'

    argument :labels, [GraphQL::Types::String],
      required: false,
      as: :label_name,
      description: 'Array of label names. All resolved merge requests will have all of these labels.'
    argument :merged_after, Types::TimeType,
      required: false,
      description: 'Merge requests merged after the date.'
    argument :merged_before, Types::TimeType,
      required: false,
      description: 'Merge requests merged before the date.'
    argument :milestone_title, GraphQL::Types::String,
      required: false,
      description: 'Title of the milestone. Incompatible with milestoneWildcardId.'
    argument :milestone_wildcard_id, ::Types::MilestoneWildcardIdEnum,
      required: false,
      description: 'Filter issues by milestone ID wildcard. Incompatible with milestoneTitle.'
    argument :review_state, ::Types::MergeRequestReviewStateEnum,
      required: false,
      description: 'Reviewer state of the merge request.',
      alpha: { milestone: '17.0' }
    argument :review_states, [::Types::MergeRequestReviewStateEnum],
      required: false,
      description: 'Reviewer states of the merge request.',
      alpha: { milestone: '17.0' }
    argument :sort, Types::MergeRequestSortEnum,
      description: 'Sort merge requests by the criteria.',
      required: false,
      default_value: :created_desc

    negated do
      argument :labels, [GraphQL::Types::String],
        required: false,
        as: :label_name,
        description: 'Array of label names. All resolved merge requests will not have these labels.'
      argument :milestone_title, GraphQL::Types::String,
        required: false,
        description: 'Title of the milestone.'
    end

    validates mutually_exclusive: [:assignee_username, :assignee_wildcard_id]
    validates mutually_exclusive: [:reviewer_username, :reviewer_wildcard_id]
    validates mutually_exclusive: [:milestone_title, :milestone_wildcard_id]

    def self.single
      ::Resolvers::MergeRequestResolver
    end

    def no_results_possible?(args)
      project.nil? || some_argument_is_empty?(args)
    end

    def some_argument_is_empty?(args)
      args.values.any? { |v| v.is_a?(Array) && v.empty? }
    end
  end
end
