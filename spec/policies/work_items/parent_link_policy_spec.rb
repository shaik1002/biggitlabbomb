# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ParentLinkPolicy, :aggregate_failures, feature_category: :team_planning do
  let_it_be_with_reload(:group1) { create(:group, :private) }
  let_it_be_with_reload(:group2) { create(:group, :private) }
  let_it_be_with_reload(:project1) { create(:project, :private, group: group1) }
  let_it_be_with_reload(:project2) { create(:project, :private, group: group2) }

  let_it_be(:guest_on_both_groups) { create(:user, guest_of: [group1, group2], name: "Guest on both groups") }
  let_it_be(:guest_on_group1) { create(:user, guest_of: [group1], name: "Guest on Group1") }
  let_it_be(:guest_on_group2) { create(:user, guest_of: [group2], name: "Guest on Group2") }

  let_it_be(:guest_on_both_projects) { create(:user, guest_of: [project1, project2], name: "Guest on both projects") }
  let_it_be(:guest_on_project1) { create(:user, guest_of: [project1], name: "Guest on Project1") }
  let_it_be(:guest_on_project2) { create(:user, guest_of: [project2], name: "Guest on Project2") }
  let_it_be(:non_member) { create(:user) }

  let_it_be(:group_work_item1) { create(:work_item, namespace: group1) }
  let_it_be(:group_work_item2) { create(:work_item, namespace: group2) }

  let_it_be(:project_work_item1) { create(:work_item, project: project1) }
  let_it_be(:project_work_item2) { create(:work_item, project: project2) }

  def permissions(user, work_item_link)
    described_class.new(user, work_item_link)
  end

  describe "#create_parent_link" do
    shared_examples 'checks permissions' do
      it 'allows the correct users' do
        allowed_users.each do |user|
          expect(permissions(user, parent_link)).to be_allowed(:create_parent_link), "#{user.name} should be allowed"
        end
      end

      it 'disallows the correct users' do
        disallowed_users.each do |user|
          expect(permissions(user, parent_link)).to be_disallowed(:create_parent_link),
            "#{user.name} should be disallowed"
        end
      end
    end

    context "for group to group work item links" do
      let(:parent_link) { build(:parent_link, work_item_parent: group_work_item1, work_item: group_work_item2) }

      context 'when groups are private' do
        it_behaves_like 'checks permissions' do
          let(:allowed_users) { [guest_on_both_groups] }
          let(:disallowed_users) do
            [guest_on_group1, guest_on_group2, guest_on_project1, guest_on_project2, guest_on_both_projects, non_member]
          end
        end
      end

      context 'when groups are public' do
        before do
          group1.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          group2.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        end

        it_behaves_like 'checks permissions' do
          let(:allowed_users) { [guest_on_both_groups] }
          let(:disallowed_users) do
            [guest_on_group1, guest_on_group2, guest_on_project1, guest_on_project2, guest_on_both_projects, non_member]
          end
        end
      end
    end

    context 'for group to project work item links' do
      let(:parent_link) { build(:parent_link, work_item_parent: group_work_item1, work_item: project_work_item1) }

      context 'when both are private' do
        it_behaves_like 'checks permissions' do
          let(:allowed_users) { [guest_on_both_groups, guest_on_group1, guest_on_project1, guest_on_both_projects] }
          let(:disallowed_users) { [guest_on_group2, guest_on_project2, non_member] }
        end
      end

      context 'when both are public' do
        before do
          group1.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          project1.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        end

        it_behaves_like 'checks permissions' do
          let(:allowed_users) do
            [
              guest_on_both_groups, guest_on_group1, guest_on_project1, guest_on_both_projects
            ]
          end

          let(:disallowed_users) { [guest_on_group2, guest_on_project2, non_member] }
        end
      end

      context 'when group is public and project is private' do
        before do
          group1.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          project1.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        end

        it_behaves_like 'checks permissions' do
          let(:allowed_users) { [guest_on_both_groups, guest_on_group1, guest_on_project1, guest_on_both_projects] }
          let(:disallowed_users) { [guest_on_group2, guest_on_project2, non_member] }
        end
      end
    end

    context 'for project to project work item links' do
      let(:parent_link) { build(:parent_link, work_item_parent: project_work_item1, work_item: project_work_item2) }

      context 'when both are private' do
        it_behaves_like 'checks permissions' do
          let(:allowed_users) do
            [
              guest_on_both_groups, guest_on_both_projects
            ]
          end

          let(:disallowed_users) do
            [guest_on_group1, guest_on_group2, guest_on_project1, guest_on_project2, non_member]
          end
        end
      end

      context 'when one is public' do
        before do
          group1.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          project1.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        end

        it_behaves_like 'checks permissions' do
          let(:allowed_users) do
            [
              guest_on_both_groups, guest_on_both_projects
            ]
          end

          let(:disallowed_users) do
            [guest_on_group1, guest_on_group2, guest_on_project1, guest_on_project2, non_member]
          end
        end
      end

      context 'when both are public' do
        before do
          group1.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          project1.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          group2.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          project2.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        end

        it_behaves_like 'checks permissions' do
          let(:allowed_users) do
            [
              guest_on_both_groups, guest_on_both_projects
            ]
          end

          let(:disallowed_users) do
            [guest_on_group1, guest_on_group2, guest_on_project1, guest_on_project2, non_member]
          end
        end
      end
    end
  end
end
