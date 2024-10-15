# frozen_string_literal: true

module Users
  class GroupCallout < ApplicationRecord
    include Users::Calloutable

    self.table_name = 'user_group_callouts'

    belongs_to :group

    enum feature_name: {
      invite_members_banner: 1,
      approaching_seat_count_threshold: 2, # EE-only
      namespace_storage_pre_enforcement_banner: 3, # EE-only
      # 4,5,6 were unused and removed with https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118330,
      # they can be replaced.
      preview_user_over_limit_free_plan_alert: 7, # EE-only
      user_reached_limit_free_plan_alert: 8, # EE-only
      free_group_limited_alert: 9, # EE-only
      # 10 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121920
      namespace_storage_limit_alert_warning_threshold: 11, # EE-only
      namespace_storage_limit_alert_alert_threshold: 12, # EE-only
      namespace_storage_limit_alert_error_threshold: 13, # EE-only
      usage_quota_trial_alert: 14, # EE-only
      preview_usage_quota_free_plan_alert: 15, # EE-only
      enforcement_at_limit_alert: 16, # EE-only
      web_hook_disabled: 17, # EE-only
      unlimited_members_during_trial_alert: 18, # EE-only
      # 19 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121920
      project_repository_limit_alert_warning_threshold: 20, # EE-only
      project_repository_limit_alert_alert_threshold: 21, # EE-only
      project_repository_limit_alert_error_threshold: 22, # EE-only
      namespace_over_storage_users_combined_alert: 23, # EE-only
      all_seats_used_alert: 24, # EE-only
      compliance_framework_settings_moved_callout: 25 # EE-only
    }

    validates :group, presence: true
    validates :feature_name,
      presence: true,
      uniqueness: { scope: [:user_id, :group_id] },
      inclusion: { in: GroupCallout.feature_names.keys }

    def source_feature_name
      "#{feature_name}_#{group_id}"
    end
  end
end
