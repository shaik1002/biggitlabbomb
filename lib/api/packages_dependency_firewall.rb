# frozen_string_literal: true

module API
  class PackagesDependencyFirewall < ::API::Base
    include ::API::Helpers::Authentication

    feature_category :package_registry
    urgency :low

    helpers ::API::Helpers::PackagesHelpers

    helpers do
      def setting
        ::Packages::DependencyFirewall::Setting.for_project!(user_project)
      end

      def create_issue(title:, description:)
        ::Issues::CreateService.new(
          container: user_project,
          current_user: current_user,
          params: {
            title: title,
            description: description,
            confidential: true
          },
          perform_spam_check: false
        ).execute
      end
    end

    authenticate_with do |accept|
      accept.token_types(:job_token).sent_through(:http_job_token_header)
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    namespace 'projects/:id/packages/dependency_firewall', requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      after_validation do
        require_packages_enabled!
        authorize_create_package!(user_project)
      end

      namespace 'package_files/:package_file_id' do
        get 'download' do
          package_file = Packages::PackageFile
            .for_package_ids(user_project.packages.processing.select(:id))
            .find(params[:package_file_id])
          present_package_file!(package_file)
        end

        put 'quarantine' do
          package_file = ::Packages::PackageFile.find(params[:package_file_id])
          package_file.package.quarantined!

          status :ok
        end

        put 'release' do
          package_file = ::Packages::PackageFile.find(params[:package_file_id])
          package_file.package.default!

          status :ok
        end
      end

      namespace 'checks' do
        params do
          requires :vulnerabilities, type: Array[Hash]
          requires :package_name, type: String
          requires :package_version, type: String
        end
        post 'dependency_scanning' do
          bad_request!('dependency_scanning check disabled') unless setting.dependency_scanning_check_enabled

          check_status = :success
          results = []

          params['vulnerabilities'].each do |vuln|
            name = vuln.dig('location', 'dependency', 'package', 'name')
            version = vuln.dig('location', 'dependency', 'version')
            next unless vuln['cvss_vectors']

            cvss_vectors = vuln['cvss_vectors'].select { |v| v['vector'].start_with?('CVSS') }
            cvss_vectors.map! { |v| CvssSuite.new(v['vector']) }
            vector = cvss_vectors.max_by(&:overall_score) # we only consider the vector with the highest score.
            urls = (vuln['links'] || []).map { |link| link['url'] } # rubocop:disable Rails/Pluck -- no AR models
            check_status = :fail if vector.overall_score >= setting.dependency_scanning_check_threshold_score

            results << {
              name: name,
              version: version,
              severity: vector.severity,
              urls: urls
            }
          end

          quarantine = check_status == :fail && setting.dependency_scanning_check_quarantine
          status(quarantine ? :bad_request : :ok)

          if setting.dependency_scanning_check_create_issue
            title = <<~TITLE
              [Dependency Firewall] Package #{params[:package_name]}, version #{params[:package_version]} failed the dependency scanning check
            TITLE
            description = <<~DESCRIPTION
              Package `#{params[:package_name]}`, version `#{params[:package_version]}` failed the dependency scanning check.

              Issues found above the `#{setting.dependency_scanning_check_threshold}` theshold:

              | Dependency name | Dependency version | Severity | Reference urls |
              | --------------- | ------------------ | -------- | -------------- |
            DESCRIPTION

            results.each do |result|
              description << <<~DESCRIPTION
                | `#{result[:name]}` | `#{result[:version]}` | `#{result[:severity]}` | #{result[:urls]} |
              DESCRIPTION
            end

            create_issue(title: title, description: description)
          end

          {
            status: check_status,
            quarantine: quarantine,
            threshold: setting.dependency_scanning_check_threshold,
            vulnerabilities: results
          }
        end

        params do
          requires :package_name, type: String
          requires :package_version, type: String
        end
        post 'deny_regex' do
          bad_request!('deny_regex check disabled') unless setting.deny_regex_check_enabled

          check_status = :success
          results = []
          name = params[:package_name]

          setting.deny_regex_check_list.each_line do |regex|
            next unless Gitlab::UntrustedRegexp.new(regex.strip).match?(name)

            results << { name: name, regex: regex }

            if setting.deny_regex_check_create_issue
              title = <<~TITLE
                [Dependency Firewall] Package #{params[:package_name]}, version #{params[:package_version]} failed the deny regex check
              TITLE
              description = <<~DESCRIPTION
                  Package `#{params[:package_name]}`, version `#{params[:package_version]}` failed the the following deny regex `#{regex}`.
              DESCRIPTION
              create_issue(title: title, description: description)
            end

            check_status = :fail
          end

          quarantine = check_status == :fail && setting.deny_regex_check_quarantine
          status(quarantine ? :bad_request : :ok)
          { status: check_status, quarantine: quarantine, matches: results }
        end

        params do
          requires :package_name, type: String
          requires :package_version, type: String
        end
        post 'owasp_dep_scan' do
          bad_request!('OWASP depscan check disabled') unless setting.owasp_dep_scan_check_enabled

          report = request.body.read
          report.force_encoding('UTF-8') # :shrug:

          check_status = :success

          if report.include?('License Scan Summary (npm)') || report.include?('Dependency Scan Results (NPM)')
            check_status = :fail
          end

          if check_status == :fail && setting.owasp_dep_scan_check_create_issue
            title = <<~TITLE
              [Dependency Firewall] Package #{params[:package_name]}, version #{params[:package_version]} failed the OWASP depscan check
            TITLE
            description = <<~DESCRIPTION
              Package `#{params[:package_name]}`, version `#{params[:package_version]}` failed the OWASP depscan check.

              Here is the HTML report:
              ```
              #{report}
              ```
            DESCRIPTION
            create_issue(title: title, description: description)
          end

          quarantine = check_status == :fail && setting.owasp_dep_scan_check_quarantine

          status(quarantine ? :bad_request : :ok)
          { status: check_status, quarantine: quarantine, report: report }
        end
      end
    end
  end
end
