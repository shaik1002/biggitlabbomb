# frozen_string_literal: true

module Packages
  module Npm
    class StartDependencyFirewallPipelineWorker
      include Gitlab::EventStore::Subscriber
      include Gitlab::Utils::StrongMemoize

      data_consistency :sticky
      queue_namespace :package_repositories
      feature_category :package_registry
      urgency :low
      idempotent!

      def self.dispatch?(event)
        event.npm? && event.user_id.present?
      end

      def handle_event(event)
        @event = event # not great
        return unless project
        return unless user

        service = ::Ci::CreatePipelineService.new(project, user, ref: project.default_branch_or_main)

        # bad, check the result of the service
        service.execute(:package_publication, content: pipeline_config) if pipeline_config
      end

      private

      # rubocop:disable Layout/LineLength -- scripts are long
      def pipeline_config
        return unless setting.run?

        base = {
          stages: %w[pull check finalize],
          variables: {
            'PACKAGE_FILE_ID' => package_file.id.to_s,
            'PACKAGE_NAME' => package_name,
            'PACKAGE_VERSION' => package_version
          },
          cache: { key: '_pgk_json', paths: ['./package/package-lock.json'] },
          pull_and_extract_pkg: {
            stage: 'pull',
            image: 'registry.gitlab.com/10io/docker_images/custom_node:22.7.0',
            script: [
              'curl --fail-with-body -vL --header "JOB-TOKEN: $CI_JOB_TOKEN" --output pkg.tgz "$CI_API_V4_URL/projects/$CI_PROJECT_ID/packages/dependency_firewall/package_files/$PACKAGE_FILE_ID/download"',
              'tar zxvf pkg.tgz',
              'cd package',
              'npm install'
            ]
          }
        }

        add_scan_deps_job(base) if setting.dependency_scanning_check_enabled
        add_deny_regex_job(base) if setting.deny_regex_check_enabled
        add_owasp_depscan_job(base) if setting.owasp_dep_scan_check_enabled

        base.to_yaml
      end
      strong_memoize_attr :pipeline_config

      # should these add_x_job/stage methods be in the model?
      def add_scan_deps_job(base)
        base[:scan_deps] = {
          stage: 'check',
          image: 'registry.gitlab.com/10io/docker_images/custom_gemnasium:5',
          script: ["/analyzer run --scan-libs", "curl --fail-with-body -X POST \"$CI_API_V4_URL/projects/$CI_PROJECT_ID/packages/dependency_firewall/checks/dependency_scanning?package_name=$PACKAGE_NAME&package_version=$PACKAGE_VERSION\" -d @gl-dependency-scanning-report.json --header \"Content-Type: application/json\" --header \"JOB-TOKEN: $CI_JOB_TOKEN\""],
          artifacts: { paths: ["gl-dependency-scanning-report.json"], expire_in: "1 week" }
        }

        add_job_to_finalize_stage(base, :scan_deps)
      end

      def add_owasp_depscan_job(base)
        base[:owasp_dep_scan] = {
          stage: 'check',
          variables: {
            'FETCH_LICENSE' => 'true'
          },
          image: 'registry.gitlab.com/10io/docker_images/owasp-dep-scan:latest',
          script: [
            "cd package",
            "depscan --explain --src . -t npm --reports-dir reports",
            "lynx --width 200 --dump --display_charset UTF-8 ./reports/depscan.html > report.txt",
            "curl --fail-with-body -X POST \"$CI_API_V4_URL/projects/$CI_PROJECT_ID/packages/dependency_firewall/checks/owasp_dep_scan?package_name=$PACKAGE_NAME&package_version=$PACKAGE_VERSION\" --data-binary @report.txt --header \"JOB-TOKEN: $CI_JOB_TOKEN\""
          ],
          artifacts: { paths: ["package/reports/depscan.html", "package/reports/license-npm.json", "package/reports/sbom.json", "package/reports/depscan-npm.json"], expire_in: "1 week" }
        }

        add_job_to_finalize_stage(base, :owasp_dep_scan)
      end

      def add_deny_regex_job(base)
        base[:deny_regex] = {
          stage: 'check',
          image: 'registry.gitlab.com/10io/docker_images/alpine_mountains',
          script: ["curl --fail-with-body -X POST \"$CI_API_V4_URL/projects/$CI_PROJECT_ID/packages/dependency_firewall/checks/deny_regex?package_name=$PACKAGE_NAME&package_version=$PACKAGE_VERSION\" --header \"Content-Type: application/json\" --header \"JOB-TOKEN: $CI_JOB_TOKEN\""]
        }

        add_job_to_finalize_stage(base, :deny_regex)
      end

      def add_job_to_finalize_stage(base, job_name)
        if base[:quarantine_pkg]
          base[:quarantine_pkg][:needs] << job_name.to_s
          base[:release_pkg][:needs] << job_name.to_s
        else
          base.merge!(
            quarantine_pkg: {
              stage: 'finalize',
              image: 'registry.gitlab.com/10io/docker_images/alpine_mountains',
              script: [
                'curl --fail-with-body -X PUT --header "JOB-TOKEN: $CI_JOB_TOKEN" "$CI_API_V4_URL/projects/$CI_PROJECT_ID/packages/dependency_firewall/package_files/$PACKAGE_FILE_ID/quarantine"'
              ],
              when: 'on_failure',
              needs: [job_name.to_s]
            },
            release_pkg: {
              stage: 'finalize',
              image: 'registry.gitlab.com/10io/docker_images/alpine_mountains',
              script: [
                'curl --fail-with-body -X PUT --header "JOB-TOKEN: $CI_JOB_TOKEN" "$CI_API_V4_URL/projects/$CI_PROJECT_ID/packages/dependency_firewall/package_files/$PACKAGE_FILE_ID/release"'
              ],
              needs: [job_name.to_s]
            }
          )
        end
      end
      # rubocop:enable Layout/LineLength

      def project
        Project.find_by_id(@event.data[:project_id])
      end
      strong_memoize_attr :project

      def user
        User.find_by_id(@event.user_id)
      end
      strong_memoize_attr :user

      def setting
        ::Packages::DependencyFirewall::Setting.for_project!(project)
      end
      strong_memoize_attr :setting

      def package_file
        ::Packages::Package.id_in(@event.data[:id]).first.package_files.last
      end
      strong_memoize_attr :package_file

      def package_name
        @event.data[:name]
      end
      strong_memoize_attr :package_name

      def package_version
        @event.data[:version]
      end
      strong_memoize_attr :package_version
    end
  end
end
