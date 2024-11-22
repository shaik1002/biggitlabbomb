# frozen_string_literal: true

module Namespaces
  class RemoveDormantMembersWorker
    include ApplicationWorker
    include LimitedCapacity::Worker

    feature_category :seat_cost_management
    data_consistency :sticky
    urgency :low

    idempotent!

    MAX_RUNNING_JOBS = 6

    def perform_work
      return unless ::Gitlab::Saas.feature_available?(:gitlab_com_subscriptions)

      namespace = find_next_namespace
      return unless namespace

      remove_dormant_members(namespace)
    end

    def remaining_work_count(*_args)
      namespaces_requiring_dormant_member_removal(max_running_jobs + 1).count
    end

    def max_running_jobs
      return 0 unless ::Feature.enabled?(:limited_capacity_dormant_member_removal) # rubocop: disable Gitlab/FeatureFlagWithoutActor -- not required

      MAX_RUNNING_JOBS
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord -- LimitedCapacity::Worker
    def find_next_namespace
      NamespaceSetting.transaction do
        namespace_setting = namespaces_requiring_dormant_member_removal
          .preload(:namespace)
          .order("last_dormant_member_review_at ASC NULLS FIRST")
          .lock('FOR UPDATE SKIP LOCKED')
          .first

        next unless namespace_setting

        # Update the last_dormant_member_review_at so the same namespace isn't picked up in parallel
        namespace_setting.update_column(:last_dormant_member_review_at, Time.current)

        namespace_setting.namespace
      end
    end

    def namespaces_requiring_dormant_member_removal(limit = 1)
      NamespaceSetting
        .where(remove_dormant_members: true)
        .where('last_dormant_member_review_at < ? OR last_dormant_member_review_at IS NULL', 18.hours.ago)
        .limit(limit)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def remove_dormant_members(namespace)
      dormant_period = namespace.namespace_settings.remove_dormant_members_period.days.ago
      admin_bot = ::Users::Internal.admin_bot

      ::GitlabSubscriptions::SeatAssignment.by_namespace(namespace).dormant(dormant_period).each do |seat_assignment|
        ::Members::ScheduleDeletionService.new(namespace, seat_assignment.user_id, admin_bot).execute
      end
    end
  end
end
