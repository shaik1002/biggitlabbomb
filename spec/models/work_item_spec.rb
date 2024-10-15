# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItem, feature_category: :portfolio_management do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:reusable_project) { create(:project) }
  let_it_be(:reusable_group) { create(:group) }

  describe 'associations' do
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to have_one(:work_item_parent).class_name('WorkItem') }

    it 'has one `parent_link`' do
      is_expected.to have_one(:parent_link)
        .class_name('::WorkItems::ParentLink')
        .with_foreign_key('work_item_id')
    end

    it 'has one `dates_source`' do
      is_expected.to have_one(:dates_source)
        .class_name('WorkItems::DatesSource')
        .with_foreign_key('issue_id')
        .inverse_of(:work_item)
    end

    it 'has many `work_item_children`' do
      is_expected.to have_many(:work_item_children)
        .class_name('WorkItem')
        .with_foreign_key('work_item_id')
    end

    it 'has many `work_item_children_by_relative_position`' do
      is_expected.to have_many(:work_item_children_by_relative_position)
        .class_name('WorkItem')
        .with_foreign_key('work_item_id')
    end

    it 'has many `child_links`' do
      is_expected.to have_many(:child_links)
        .class_name('::WorkItems::ParentLink')
        .with_foreign_key('work_item_parent_id')
    end
  end

  describe '.work_item_children_by_relative_position' do
    subject { parent_item.reload.work_item_children_by_relative_position }

    let_it_be(:parent_item) { create(:work_item, :objective, project: reusable_project) }
    let_it_be(:oldest_item) { create(:work_item, :objective, created_at: 5.hours.ago, project: reusable_project) }
    let_it_be(:middle_item) { create(:work_item, :objective, project: reusable_project) }
    let_it_be(:newest_item) { create(:work_item, :objective, created_at: 5.hours.from_now, project: reusable_project) }

    let_it_be_with_reload(:link_to_oldest_item) do
      create(:parent_link, work_item_parent: parent_item, work_item: oldest_item)
    end

    let_it_be_with_reload(:link_to_middle_item) do
      create(:parent_link, work_item_parent: parent_item, work_item: middle_item)
    end

    let_it_be_with_reload(:link_to_newest_item) do
      create(:parent_link, work_item_parent: parent_item, work_item: newest_item)
    end

    context 'when ordered by relative position and created_at' do
      using RSpec::Parameterized::TableSyntax

      where(:oldest_item_position, :middle_item_position, :newest_item_position, :expected_order) do
        nil | nil | nil | lazy { [oldest_item, middle_item, newest_item] }
        nil | nil | 1   | lazy { [newest_item, oldest_item, middle_item] }
        nil | 1   | 2   | lazy { [middle_item, newest_item, oldest_item] }
        2   | 3   | 1   | lazy { [newest_item, oldest_item, middle_item] }
        1   | 2   | 3   | lazy { [oldest_item, middle_item, newest_item] }
      end

      with_them do
        before do
          link_to_oldest_item.update!(relative_position: oldest_item_position)
          link_to_middle_item.update!(relative_position: middle_item_position)
          link_to_newest_item.update!(relative_position: newest_item_position)
        end

        it { is_expected.to eq(expected_order) }
      end
    end
  end

  describe '#noteable_target_type_name' do
    it 'returns `issue` as the target name' do
      work_item = build(:work_item)

      expect(work_item.noteable_target_type_name).to eq('issue')
    end
  end

  describe '#todoable_target_type_name' do
    it 'returns correct target name' do
      work_item = build(:work_item)

      expect(work_item.todoable_target_type_name).to contain_exactly('Issue', 'WorkItem')
    end
  end

  describe '#widgets' do
    subject { build(:work_item).widgets }

    it 'returns instances of supported widgets' do
      is_expected.to include(
        instance_of(WorkItems::Widgets::Description),
        instance_of(WorkItems::Widgets::Hierarchy),
        instance_of(WorkItems::Widgets::Labels),
        instance_of(WorkItems::Widgets::Assignees),
        instance_of(WorkItems::Widgets::StartAndDueDate)
      )
    end
  end

  describe '#get_widget' do
    let(:work_item) { build(:work_item, description: 'foo') }

    it 'returns widget object' do
      expect(work_item.get_widget(:description)).to be_an_instance_of(WorkItems::Widgets::Description)
    end

    context 'when widget does not exist' do
      it 'returns nil' do
        expect(work_item.get_widget(:nop)).to be_nil
      end
    end
  end

  describe '#supports_assignee?' do
    Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter::WIDGETS_FOR_TYPE.each_pair do |base_type, widgets|
      specify do
        work_item = build(:work_item, base_type)
        supports_assignee = widgets.include?(:assignees)

        expect(work_item.supports_assignee?).to eq(supports_assignee)
      end
    end
  end

  describe '#supports_time_tracking?' do
    Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter::WIDGETS_FOR_TYPE.each_pair do |base_type, widgets|
      specify do
        work_item = build(:work_item, base_type)
        supports_time_tracking = widgets.include?(:time_tracking)

        expect(work_item.supports_time_tracking?).to eq(supports_time_tracking)
      end
    end
  end

  describe '#supported_quick_action_commands' do
    let(:work_item) { build(:work_item, :task) }

    subject { work_item.supported_quick_action_commands }

    it 'returns quick action commands supported for all work items' do
      is_expected.to include(:title, :reopen, :close, :cc, :tableflip, :shrug, :type, :promote_to, :checkin_reminder,
        :subscribe, :unsubscribe, :confidential, :award)
    end

    context 'when work item supports the assignee widget' do
      it 'returns assignee related quick action commands' do
        is_expected.to include(:assign, :unassign, :reassign)
      end
    end

    context 'when work item does not the assignee widget' do
      let(:work_item) { build(:work_item, :test_case) }

      it 'omits assignee related quick action commands' do
        is_expected.not_to include(:assign, :unassign, :reassign)
      end
    end

    context 'when work item supports the labels widget' do
      it 'returns labels related quick action commands' do
        is_expected.to include(:label, :labels, :relabel, :remove_label, :unlabel)
      end
    end

    context 'when work item does not support the labels widget' do
      let(:work_item) { build(:work_item, :incident) }

      it 'omits labels related quick action commands' do
        is_expected.not_to include(:label, :labels, :relabel, :remove_label, :unlabel)
      end
    end

    context 'when work item supports the start and due date widget' do
      it 'returns due date related quick action commands' do
        is_expected.to include(:due, :remove_due_date)
      end
    end

    context 'when work item does not support the start and due date widget' do
      let(:work_item) { build(:work_item, :incident) }

      it 'omits due date related quick action commands' do
        is_expected.not_to include(:due, :remove_due_date)
      end
    end

    context 'when work item supports the current user todos widget' do
      it 'returns todos related quick action commands' do
        is_expected.to include(:todo, :done)
      end
    end

    context 'when work item does not support current user todos widget' do
      let(:work_item) { build(:work_item, :task) }

      before do
        WorkItems::Type.default_by_type(:task).widget_definitions
                       .find_by_widget_type(:current_user_todos).update!(disabled: true)
      end

      it 'omits todos related quick action commands' do
        is_expected.not_to include(:todo, :done)
      end
    end
  end

  describe 'transform_quick_action_params' do
    let(:command_params) { { title: 'bar', assignee_ids: ['foo'] } }
    let(:work_item) { build(:work_item, :task) }

    subject(:transformed_params) { work_item.transform_quick_action_params(command_params) }

    it 'correctly separates widget params from regular params' do
      expect(transformed_params).to eq({
        common: {
          title: 'bar'
        },
        widgets: {
          assignees_widget: {
            assignee_ids: ['foo']
          }
        }
      })
    end

    context 'with current user todos widget' do
      let(:command_params) { { title: 'bar', todo_event: param } }

      where(:param, :expected) do
        'done' | 'mark_as_done'
        'add'  | 'add'
      end

      with_them do
        it 'correctly transform todo_event param' do
          expect(transformed_params).to eq({
            common: {
              title: 'bar'
            },
            widgets: {
              current_user_todos_widget: {
                action: expected
              }
            }
          })
        end
      end
    end
  end

  describe 'callbacks' do
    describe 'record_create_action' do
      it 'records the creation action after saving' do
        expect(Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter).to receive(:track_work_item_created_action)
        # During the work item transition we also want to track work items as issues
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_created_action)

        create(:work_item)
      end

      it_behaves_like 'internal event tracking' do
        let(:work_item) { create(:work_item) }
        let(:event) { Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_CREATED }
        let(:project) { work_item.project }
        let(:user) { work_item.author }
        let(:namespace) { project.namespace }

        subject(:service_action) { work_item }
      end
    end

    context 'work item namespace' do
      let(:work_item) { build(:work_item, project: reusable_project) }

      it 'sets the namespace_id' do
        expect(work_item).to be_valid
        expect(work_item.namespace).to eq(reusable_project.project_namespace)
      end

      context 'when work item is saved' do
        it 'sets the namespace_id' do
          work_item.save!
          expect(work_item.reload.namespace).to eq(reusable_project.project_namespace)
        end
      end

      context 'when existing work item is saved' do
        let(:work_item) { create(:work_item) }

        before do
          work_item.update!(namespace_id: nil)
        end

        it 'sets the namespace id' do
          work_item.update!(title: "#{work_item.title} and something extra")

          expect(work_item.namespace).to eq(work_item.project.project_namespace)
        end
      end
    end

    context 'with title containing preceding or trailing spaces' do
      let_it_be(:work_item) { build(:work_item, project: reusable_project, title: " some title ") }

      it 'removes spaces from title' do
        work_item.save!

        expect(work_item.title).to eq("some title")
      end
    end
  end

  describe 'validations' do
    subject { work_item.valid? }

    describe 'confidentiality' do
      let_it_be(:project) { create(:project) }

      context 'when parent and child are confidential' do
        let_it_be(:parent) { create(:work_item, confidential: true, project: project) }
        let_it_be(:child) { create(:work_item, :task, confidential: true, project: project) }
        let_it_be(:link) { create(:parent_link, work_item: child, work_item_parent: parent) }

        it 'does not allow to make child non-confidential' do
          child.confidential = false

          expect(child).not_to be_valid
          expect(child.errors[:base])
            .to include(_('A non-confidential work item cannot have a confidential parent.'))
        end

        it 'allows to make parent non-confidential' do
          parent.confidential = false

          expect(parent).to be_valid
        end
      end

      context 'when parent and child are non-confidential' do
        let_it_be(:parent) { create(:work_item, project: project) }
        let_it_be(:child) { create(:work_item, :task, project: project) }
        let_it_be(:link) { create(:parent_link, work_item: child, work_item_parent: parent) }

        it 'does not allow to make parent confidential' do
          parent.confidential = true

          expect(parent).not_to be_valid
          expect(parent.errors[:base]).to include(
            _('A confidential work item cannot have a parent that already has non-confidential children.')
          )
        end

        it 'allows to make child confidential' do
          child.confidential = true

          expect(child).to be_valid
        end
      end

      context 'when creating new child' do
        let_it_be(:child) { build(:work_item, project: project) }

        it 'does not allow to set confidential parent' do
          child.work_item_parent = create(:work_item, confidential: true, project: project)

          expect(child).not_to be_valid
          expect(child.errors[:base])
            .to include('A non-confidential work item cannot have a confidential parent.')
        end
      end
    end
  end

  describe '#link_reference_pattern' do
    let(:match_data) { described_class.link_reference_pattern.match(link_reference_url) }

    context 'with work item url' do
      let(:link_reference_url) { 'http://localhost/namespace/project/-/work_items/1' }

      it 'matches with expected attributes' do
        expect(match_data['namespace']).to eq('namespace')
        expect(match_data['project']).to eq('project')
        expect(match_data['work_item']).to eq('1')
      end
    end
  end

  describe '#linked_items_keyset_order' do
    subject { described_class.linked_items_keyset_order }

    it { is_expected.to eq('"issue_links"."id" ASC') }
  end

  context 'with hierarchy' do
    let_it_be(:type1) { create(:work_item_type, namespace: reusable_project.namespace) }
    let_it_be(:type2) { create(:work_item_type, namespace: reusable_project.namespace) }
    let_it_be(:type3) { create(:work_item_type, namespace: reusable_project.namespace) }
    let_it_be(:type4) { create(:work_item_type, namespace: reusable_project.namespace) }
    let_it_be(:hierarchy_restriction1) { create(:hierarchy_restriction, parent_type: type1, child_type: type2) }
    let_it_be(:hierarchy_restriction2) { create(:hierarchy_restriction, parent_type: type2, child_type: type2) }
    let_it_be(:hierarchy_restriction3) { create(:hierarchy_restriction, parent_type: type2, child_type: type3) }
    let_it_be(:hierarchy_restriction4) { create(:hierarchy_restriction, parent_type: type3, child_type: type3) }
    let_it_be(:hierarchy_restriction5) { create(:hierarchy_restriction, parent_type: type3, child_type: type4) }
    let_it_be(:item1) { create(:work_item, work_item_type: type1, project: reusable_project) }
    let_it_be(:item2_1) { create(:work_item, work_item_type: type2, project: reusable_project) }
    let_it_be(:item2_2) { create(:work_item, work_item_type: type2, project: reusable_project) }
    let_it_be(:item3_1) { create(:work_item, work_item_type: type3, project: reusable_project) }
    let_it_be(:item3_2) { create(:work_item, work_item_type: type3, project: reusable_project) }
    let_it_be(:item4) { create(:work_item, work_item_type: type4, project: reusable_project) }
    let_it_be(:ignored_ancestor) { create(:work_item, work_item_type: type1, project: reusable_project) }
    let_it_be(:ignored_descendant) { create(:work_item, work_item_type: type4, project: reusable_project) }
    let_it_be(:link1) { create(:parent_link, work_item_parent: item1, work_item: item2_1) }
    let_it_be(:link2) { create(:parent_link, work_item_parent: item2_1, work_item: item2_2) }
    let_it_be(:link3) { create(:parent_link, work_item_parent: item2_2, work_item: item3_1) }
    let_it_be(:link4) { create(:parent_link, work_item_parent: item3_1, work_item: item3_2) }
    let_it_be(:link5) { create(:parent_link, work_item_parent: item3_2, work_item: item4) }

    describe '#ancestors' do
      it 'returns all ancestors in ascending order' do
        expect(item3_1.ancestors).to eq([item2_2, item2_1, item1])
      end

      it 'returns an empty array if there are no ancestors' do
        expect(item1.ancestors).to be_empty
      end
    end

    describe '#same_type_base_and_ancestors' do
      it 'returns self and all ancestors of the same type in ascending order' do
        expect(item3_2.same_type_base_and_ancestors).to eq([item3_2, item3_1])
      end

      it 'returns self if there are no ancestors of the same type' do
        expect(item3_1.same_type_base_and_ancestors).to match_array([item3_1])
      end
    end

    describe '#same_type_descendants_depth' do
      it 'returns max descendants depth including self' do
        expect(item3_1.same_type_descendants_depth).to eq(2)
      end

      it 'returns 1 if there are no descendants' do
        expect(item1.same_type_descendants_depth).to eq(1)
      end
    end
  end

  describe '#allowed_work_item_type_change' do
    let_it_be(:all_types) { WorkItems::Type::BASE_TYPES.keys }

    it 'is possible to change between all types', :aggregate_failures do
      all_types.each do |type|
        work_item = build(:work_item, type, project: reusable_project)

        (all_types - [type]).each do |new_type|
          work_item.work_item_type_id = WorkItems::Type.default_by_type(new_type).id

          expect(work_item).to be_valid, "#{type} to #{new_type}"
        end
      end
    end

    context 'with ParentLink relation' do
      let_it_be(:old_type) { create(:work_item_type) }
      let_it_be(:new_type) { create(:work_item_type) }

      context 'with hierarchy restrictions' do
        let_it_be(:child_type) { create(:work_item_type) }

        let_it_be_with_reload(:parent) { create(:work_item, work_item_type: old_type, project: reusable_project) }
        let_it_be_with_reload(:child) { create(:work_item, work_item_type: child_type, project: reusable_project) }

        let_it_be(:hierarchy_restriction) do
          create(:hierarchy_restriction, parent_type: old_type, child_type: child_type)
        end

        let_it_be(:link) { create(:parent_link, work_item_parent: parent, work_item: child) }

        context 'when child items restrict the type change' do
          before do
            parent.work_item_type = new_type
          end

          context 'when child items are compatible with the new type' do
            let_it_be(:hierarchy_restriction_new_type) do
              create(:hierarchy_restriction, parent_type: new_type, child_type: child_type)
            end

            it 'allows to change types' do
              expect(parent).to be_valid
              expect(parent.errors).to be_empty
            end
          end

          context 'when child items are not compatible with the new type' do
            it 'does not allow to change types' do
              expect(parent).not_to be_valid
              expect(parent.errors[:work_item_type_id])
                .to include("cannot be changed to #{new_type.name} with these child item types.")
            end
          end
        end

        context 'when the parent restricts the type change' do
          before do
            child.work_item_type = new_type
          end

          it 'does not allow to change types' do
            expect(child.valid?).to eq(false)
            expect(child.errors[:work_item_type_id]).to include(
              format(
                "cannot be changed to %{type_name} when linked to a parent %{parent_name}.",
                type_name: new_type.name.downcase,
                parent_name: parent.work_item_type.name.downcase
              )
            )
          end
        end
      end

      context 'with hierarchy depth restriction' do
        let_it_be_with_reload(:item1) { create(:work_item, work_item_type: new_type, project: reusable_project) }
        let_it_be_with_reload(:item2) { create(:work_item, work_item_type: new_type, project: reusable_project) }
        let_it_be_with_reload(:item3) { create(:work_item, work_item_type: new_type, project: reusable_project) }
        let_it_be_with_reload(:item4) { create(:work_item, work_item_type: new_type, project: reusable_project) }

        let_it_be(:hierarchy_restriction1) do
          create(:hierarchy_restriction, parent_type: old_type, child_type: new_type)
        end

        let_it_be(:hierarchy_restriction2) do
          create(:hierarchy_restriction, parent_type: new_type, child_type: old_type)
        end

        let_it_be_with_reload(:hierarchy_restriction3) do
          create(:hierarchy_restriction, parent_type: new_type, child_type: new_type, maximum_depth: 4)
        end

        let_it_be(:link1) { create(:parent_link, work_item_parent: item1, work_item: item2) }
        let_it_be(:link2) { create(:parent_link, work_item_parent: item2, work_item: item3) }
        let_it_be(:link3) { create(:parent_link, work_item_parent: item3, work_item: item4) }

        before do
          hierarchy_restriction3.update!(maximum_depth: maximum_depth)
        end

        shared_examples 'validates the depth correctly' do
          before do
            work_item.update!(work_item_type: old_type)
          end

          context 'when it is valid' do
            let(:maximum_depth) { 4 }

            it 'allows to change types' do
              work_item.work_item_type = new_type

              expect(work_item).to be_valid
            end
          end

          context 'when it is not valid' do
            let(:maximum_depth) { 3 }

            it 'does not allow to change types' do
              work_item.work_item_type = new_type

              expect(work_item).not_to be_valid
              expect(work_item.errors[:work_item_type_id]).to include("reached maximum depth")
            end
          end
        end

        context 'with the highest ancestor' do
          let_it_be_with_reload(:work_item) { item1 }

          it_behaves_like 'validates the depth correctly'
        end

        context 'with a child item' do
          let_it_be_with_reload(:work_item) { item2 }

          it_behaves_like 'validates the depth correctly'
        end

        context 'with the last child item' do
          let_it_be_with_reload(:work_item) { item4 }

          it_behaves_like 'validates the depth correctly'
        end

        context 'when ancestor is still the old type' do
          let_it_be(:hierarchy_restriction4) do
            create(:hierarchy_restriction, parent_type: old_type, child_type: old_type)
          end

          before do
            item1.update!(work_item_type: old_type)
            item2.update!(work_item_type: old_type)
          end

          context 'when it exceeds maximum depth' do
            let(:maximum_depth) { 2 }

            it 'does not allow to change types' do
              item2.work_item_type = new_type

              expect(item2).not_to be_valid
              expect(item2.errors[:work_item_type_id]).to include("reached maximum depth")
            end
          end

          context 'when it does not exceed maximum depth' do
            let(:maximum_depth) { 3 }

            it 'does allow to change types' do
              item2.work_item_type = new_type

              expect(item2).to be_valid
            end
          end
        end
      end
    end
  end

  describe '#linked_work_items' do
    let_it_be(:user) { create(:user) }
    let_it_be(:authorized_project) { create(:project) }
    let_it_be(:authorized_project2) { create(:project) }
    let_it_be(:unauthorized_project) { create(:project, :private) }

    let_it_be(:authorized_item_a) { create(:work_item, project: authorized_project) }
    let_it_be(:authorized_item_b) { create(:work_item, project: authorized_project) }
    let_it_be(:authorized_item_c) { create(:work_item, project: authorized_project2) }
    let_it_be(:unauthorized_item) { create(:work_item, project: unauthorized_project) }

    let_it_be(:work_item_link_a) { create(:work_item_link, source: authorized_item_a, target: authorized_item_b) }
    let_it_be(:work_item_link_b) { create(:work_item_link, source: authorized_item_a, target: unauthorized_item) }
    let_it_be(:work_item_link_c) { create(:work_item_link, source: authorized_item_a, target: authorized_item_c) }

    before_all do
      authorized_project.add_guest(user)
      authorized_project2.add_guest(user)
    end

    it 'returns only authorized linked work items for given user' do
      expect(authorized_item_a.linked_work_items(user)).to contain_exactly(authorized_item_b, authorized_item_c)
    end

    it 'returns work items with valid work_item_link_type' do
      link_types = authorized_item_a.linked_work_items(user).map(&:issue_link_type)

      expect(link_types).not_to be_empty
      expect(link_types).not_to include(nil)
    end

    it 'returns work items including the link creation time' do
      dates = authorized_item_a.linked_work_items(user).map(&:issue_link_created_at)

      expect(dates).not_to be_empty
      expect(dates).not_to include(nil)
    end

    it 'returns work items including the link update time' do
      dates = authorized_item_a.linked_work_items(user).map(&:issue_link_updated_at)

      expect(dates).not_to be_empty
      expect(dates).not_to include(nil)
    end

    context 'when a user cannot read cross project' do
      it 'only returns work items within the same project' do
        allow(Ability).to receive(:allowed?).with(user, :read_all_resources, :global).and_call_original
        expect(Ability).to receive(:allowed?).with(user, :read_cross_project).and_return(false)

        expect(authorized_item_a.linked_work_items(user)).to contain_exactly(authorized_item_b)
      end
    end

    context 'when filtering by link type' do
      before do
        work_item_link_c.update!(link_type: 'blocks')
      end

      it 'returns authorized work items with given link type' do
        expect(authorized_item_a.linked_work_items(user, link_type: 'relates_to')).to contain_exactly(authorized_item_b)
      end
    end

    context 'when authorize option is true and current_user is nil' do
      it 'returns empty result' do
        expect(authorized_item_a.linked_work_items).to be_empty
      end
    end

    context 'when authorize option is false' do
      it 'returns all work items linked to the work item' do
        expect(authorized_item_a.linked_work_items(authorize: false))
          .to contain_exactly(authorized_item_b, authorized_item_c, unauthorized_item)
      end
    end

    context 'when work item is a new record' do
      let(:new_work_item) { build(:work_item, project: authorized_project) }

      it { expect(new_work_item.linked_work_items(user)).to be_empty }
    end
  end

  describe '#linked_items_count' do
    let_it_be(:item1) { create(:work_item, :issue, project: reusable_project) }
    let_it_be(:item2) { create(:work_item, :issue, project: reusable_project) }
    let_it_be(:item3) { create(:work_item, :issue, project: reusable_project) }
    let_it_be(:item4) { build(:work_item, :issue, project: reusable_project) }

    it 'returns number of items linked to the work item' do
      create(:work_item_link, source: item1, target: item2)
      create(:work_item_link, source: item1, target: item3)

      expect(item1.linked_items_count).to eq(2)
      expect(item2.linked_items_count).to eq(1)
      expect(item3.linked_items_count).to eq(1)
      expect(item4.linked_items_count).to eq(0)
    end
  end

  context 'work item participants' do
    context 'project level work item' do
      let_it_be(:work_item) { create(:work_item, project: reusable_project) }

      it 'has participants' do
        expect(work_item.participants).to match_array([work_item.author])
      end
    end

    context 'group level work item' do
      let_it_be(:work_item) { create(:work_item, namespace: reusable_group) }

      it 'has participants' do
        expect(work_item.participants).to match_array([work_item.author])
      end
    end
  end
end
