# frozen_string_literal: true

module QA
  describe 'Manage', product_group: :import_and_integrate do
    describe 'Gitlab migration', :orchestrated, :import_with_smtp,
      feature_flag: { name: :importer_user_mapping },
      feature_flag: { name: :bulk_import_importer_user_mapping } do # rubocop:disable Lint/DuplicateHashKey -- Second feature flag
      include_context "with gitlab project migration"

      context 'with user contribution reassignment' do
        let(:mail_hog) { Vendor::MailHog::API.new }
        let(:reassignment_email_subject) { "Reassignments on #{target_sandbox.name} waiting for review" }
        let!(:source_project_with_readme) { true }

        let!(:source_issue) do
          create(:issue, project: source_project, labels: %w[label_one label_two],
            api_client: source_admin_api_client)
        end

        let!(:source_issue_comment) { source_issue.add_comment(body: 'This is a test issue comment!') }

        let!(:source_mr) do
          create(:merge_request, project: source_project, api_client: source_admin_api_client)
        end

        let!(:source_mr_comment) { source_mr.add_comment(body: 'This is a test mr comment!') }

        let!(:imported_group) do
          Resource::BulkImportGroup.init do |group|
            group.api_client = api_client
            group.sandbox = target_sandbox
            group.source_group = source_group
          end
        end

        let(:imported_issue) { imported_project.issues.first }

        let(:imported_merge_request) { imported_project.merge_requests.first }

        let(:placeholder_user) do
          build(:user,
            username: "#{source_admin_user.username}_placeholder_user_3",
            name: "Placeholder #{source_admin_user.name}")
        end

        before do
          Runtime::Feature.enable(:importer_user_mapping)
          Runtime::Feature.enable(:bulk_import_importer_user_mapping)

          Flow::Login.sign_in(as: user)
          Resource::BulkImportGroup.fabricate_via_browser_ui! do |group|
            group.api_client = api_client
            group.sandbox = target_sandbox
            group.source_group = source_group
            group.source_gitlab_address = source_gitlab_address
            group.destination_group_path = destination_group_path
            group.import_access_token = source_admin_api_client.personal_access_token
          end
          imported_merge_request
          imported_issue
        end

        it 'reassigns placeholder users to reassigned users in issues and merge requests after reassignment',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/504548' do
            page.visit imported_merge_request[:web_url]
            Page::MergeRequest::Show.perform do |merge_request|
              expect(merge_request).to have_author(placeholder_user.name)
              expect(merge_request).to have_comment_author(placeholder_user.name)
            end

            page.visit imported_issue[:web_url]
            Page::Project::Issue::Show.perform do |issue|
              expect(issue).to have_author(placeholder_user.name)
              expect(issue).to have_comment_author(placeholder_user.name)
            end

            target_sandbox.visit!
            Page::Group::Menu.perform(&:go_to_members)
            Page::Group::Members.perform do |members_page|
              expect(members_page).to have_tab_count("Placeholders", 1)
              members_page.click_tab("Placeholders")

              expect(members_page).to have_tab_count("Awaiting reassignment", 1)
              expect(members_page).to have_tab_count("Reassigned", 0)

              expect(members_page).to have_reassignment_status(placeholder_user.username, "Not started")
              members_page.reassign_placeholder_user(placeholder_user.username, user.username)
              expect(members_page).to have_reassignment_status(placeholder_user.username, "Pending approval")
            end

            expect { email_subjects }.to eventually_include(reassignment_email_subject).within(max_duration: 300)
            page.visit reassignment_url
            click_approve_reassignment

            target_sandbox.visit!
            Page::Group::Menu.perform(&:go_to_members)
            Page::Group::Members.perform do |members_page|
              members_page.click_tab("Placeholders")

              expect(members_page).to have_tab_count("Awaiting reassignment", 1)

              expect(members_page).to have_reassignment_status(placeholder_user.username, "Reassigning")
              members_page.reassignment_completed?(placeholder_user.username)
              members_page.click_tab("Reassigned")
              expect(members_page).to have_reassignment_status(placeholder_user.username, "Success")
              expect(members_page).to have_tab_count("Reassigned", 1)
            end

            page.visit imported_merge_request[:web_url]
            Page::MergeRequest::Show.perform do |merge_request|
              expect(merge_request).to have_author(user.name)
              expect(merge_request).to have_comment_author(user.name)
            end

            page.visit imported_issue[:web_url]
            Page::Project::Issue::Show.perform do |issue|
              expect(issue).to have_author(user.name)
              expect(issue).to have_comment_author(user.name)
            end
          end
      end

      private

      def mail_hog_messages
        Support::Retrier.retry_until(sleep_interval: 1) do
          Runtime::Logger.debug('Fetching email...')

          messages = mail_hog.fetch_messages
          logs = messages.map { |m| "#{m.to}: #{m.subject}" }

          Runtime::Logger.debug("MailHog Logs: #{logs.join("\n")}")

          messages
        end
      end

      def email_subjects
        mail_hog_messages.map(&:subject)
      end

      def email_body
        mail_hog_messages.map(&:body)
      end

      def reassignment_url
        pattern = %r{/https?://[\S+]*/import/source_users/[-A-Z0-9]*/i}
        email_body[0].match(pattern).to_s
      end

      def click_approve_reassignment
        find('.gl-button-text', text: "Approve reassignment").click
      end
    end
  end
end
