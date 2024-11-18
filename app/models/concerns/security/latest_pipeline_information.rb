# frozen_string_literal: true

module Security
  module LatestPipelineInformation
    private

    def scanner_enabled?(scan_type)
      latest_builds_reports.include?(scan_type)
    end

    def latest_builds_reports(only_successful_builds: false)
      strong_memoize("latest_builds_reports_#{only_successful_builds}") do
        builds = latest_security_builds
        builds = builds.select { |build| build.status == 'success' } if only_successful_builds
        reports = builds.flat_map do |build|
          build.options[:artifacts][:reports].keys
        end

        reports.delete(:sast)
        reports << :sast if builds.map(&:name).any?('sast')
        reports << :sast_iac if builds.map(&:name).any? { |n| n.include?('iac') }
        reports << :sast_advanced if builds.map(&:name).any? { |n| n.include?('advanced-sast') }
        reports
      end
    end

    def latest_security_builds
      return [] unless latest_default_branch_pipeline

      ::Security::SecurityJobsFinder.new(pipeline: latest_default_branch_pipeline).execute +
        ::Security::LicenseComplianceJobsFinder.new(pipeline: latest_default_branch_pipeline).execute
    end

    def latest_default_branch_pipeline
      strong_memoize(:pipeline) { latest_pipeline }
    end

    def auto_devops_source?
      latest_default_branch_pipeline&.auto_devops_source?
    end
  end
end
