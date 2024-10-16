# frozen_string_literal: true

require "spec_helper"

RSpec.describe WorkItemsHelper, feature_category: :team_planning do
  include Devise::Test::ControllerHelpers
  describe '#work_items_show_data' do
    subject(:work_items_show_data) { helper.work_items_show_data(project) }

    let_it_be(:project) { build(:project) }

    it 'returns the expected data properties' do
      expect(work_items_show_data).to include(
        {
          full_path: project.full_path,
          group_path: nil,
          issues_list_path: project_issues_path(project),
          register_path: new_user_registration_path(redirect_to_referer: 'yes'),
          sign_in_path: user_session_path(redirect_to_referer: 'yes'),
          new_comment_template_paths:
            [{ text: "Your comment templates", href: profile_comment_templates_path }].to_json,
          report_abuse_path: add_category_abuse_reports_path
        }
      )
    end

    context 'when project is under a group' do
      let(:group) { build(:group) }
      let(:group_project) { build(:project, group: group) }

      subject(:work_items_show_data) { helper.work_items_show_data(group_project) }

      it 'returns the expected group_path' do
        expect(work_items_show_data).to include(
          {
            group_path: group_project.group.full_path
          }
        )
      end
    end
  end

  describe '#work_items_list_data' do
    let_it_be(:group) { build(:group) }

    let(:current_user) { double.as_null_object }

    subject(:work_items_list_data) { helper.work_items_list_data(group, current_user) }

    it 'returns expected data' do
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(helper).to receive(:can?).and_return(true)

      expect(work_items_list_data).to include(
        {
          full_path: group.full_path,
          initial_sort: current_user&.user_preference&.issues_sort,
          is_signed_in: current_user.present?.to_s,
          show_new_issue_link: 'true'
        }
      )
    end
  end
end
