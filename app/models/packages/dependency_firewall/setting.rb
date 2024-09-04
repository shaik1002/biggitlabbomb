# frozen_string_literal: true

module Packages
  module DependencyFirewall
    class Setting < ApplicationRecord
      belongs_to :project

      enum dependency_scanning_check_threshold: {
        disabled: 0,
        level_none: 1,
        level_low: 2,
        level_medium: 3,
        level_high: 4,
        level_critical: 5
      }

      scope :for_project!, ->(project) { find_by!(project_id: project.id) }

      def self.find_or_initialize_for_project(project)
        find_or_initialize_by(project_id: project.id)
      end

      # see https://www.first.org/cvss/specification-document#Qualitative-Severity-Rating-Scale
      def dependency_scanning_check_threshold_score
        return 0.0 if level_none?
        return 0.1 if level_low?
        return 4.0 if level_medium?
        return 7.0 if level_high?
        return 9.0 if level_critical?

        100
      end

      def run?
        dependency_scanning_check_enabled || deny_regex_check_enabled || owasp_dep_scan_check_enabled
      end
    end
  end
end
