# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::IssuesMenu, feature_category: :navigation do
  let(:project) { build(:project) }
  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  subject { described_class.new(context) }

  it_behaves_like 'serializable as super_sidebar_menu_args' do
    let(:menu) { subject }
    let(:extra_attrs) do
      {
        item_id: :project_issue_list,
        active_routes: { path: %w[projects/issues#index projects/issues#show projects/issues#new] },
        pill_count: menu.pill_count,
        pill_count_field: menu.pill_count_field,
        has_pill: menu.has_pill?,
        super_sidebar_parent: Sidebars::Projects::SuperSidebarMenus::PlanMenu
      }
    end
  end

  describe '#render?' do
    context 'when user can read issues' do
      it 'returns true' do
        expect(subject.render?).to eq true
      end
    end

    context 'when user cannot read issues' do
      let(:user) { nil }

      it 'returns false' do
        expect(subject.render?).to eq false
      end
    end
  end

  describe '#has_pill?' do
    context 'when issues feature is enabled' do
      it 'returns true' do
        expect(subject.has_pill?).to eq true
      end
    end

    context 'when issue feature is disabled' do
      it 'returns false' do
        allow(project).to receive(:issues_enabled?).and_return(false)

        expect(subject.has_pill?).to eq false
      end
    end
  end

  describe '#pill_count' do
    before do
      stub_feature_flags(async_sidebar_counts: false)
    end

    it 'returns zero when there are no open issues' do
      expect(subject.pill_count).to eq '0'
    end

    it 'memoizes the query' do
      subject.pill_count

      control = ActiveRecord::QueryRecorder.new do
        subject.pill_count
      end

      expect(control.count).to eq 0
    end

    context 'when there are open issues' do
      it 'returns the number of open issues' do
        create_list(:issue, 2, :opened, project: project)
        build_stubbed(:issue, :closed, project: project)

        expect(subject.pill_count).to eq '2'
      end
    end

    describe 'formatting' do
      it 'returns truncated digits for count value over 1000' do
        facade_instance = instance_double(WorkItems::CountOpenIssuesForProject)
        allow(WorkItems::CountOpenIssuesForProject).to receive(:new).with(project: project).and_return(facade_instance)
        expect(facade_instance).to receive(:count).with(user).and_return(1001)

        expect(subject.pill_count).to eq('1k')
      end
    end

    context 'when async_sidebar_counts feature flag is enabled' do
      before do
        stub_feature_flags(async_sidebar_counts: true)
      end

      it 'returns nil' do
        expect(subject.pill_count).to be_nil
      end
    end
  end

  describe '#pill_count_field' do
    it 'returns the correct GraphQL field name' do
      expect(subject.pill_count_field).to eq('openIssuesCount')
    end

    context 'when async_sidebar_counts feature flag is disabled' do
      before do
        stub_feature_flags(async_sidebar_counts: false)
      end

      it 'returns nil' do
        expect(subject.pill_count_field).to be_nil
      end
    end
  end

  describe 'Menu Items' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

    describe 'Service Desk' do
      let(:item_id) { :service_desk }

      describe 'when service desk is supported' do
        before do
          allow(Gitlab::ServiceDesk).to receive(:supported?).and_return(true)
        end

        describe 'when service desk is enabled' do
          before do
            project.update!(service_desk_enabled: true)
          end

          it { is_expected.not_to be_nil }
        end

        describe 'when service desk is disabled' do
          before do
            project.update!(service_desk_enabled: false)
          end

          it { is_expected.to be_nil }
        end
      end

      describe 'when service desk is unsupported' do
        before do
          allow(Gitlab::ServiceDesk).to receive(:supported?).and_return(false)
          project.update!(service_desk_enabled: true)
        end

        it { is_expected.to be_nil }
      end
    end
  end
end
