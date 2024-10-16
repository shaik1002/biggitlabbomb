# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ParentLinks::CreateService, feature_category: :portfolio_management do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:guest) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:work_item) { create(:work_item, project: project) }
    let_it_be(:task) { create(:work_item, :task, project: project) }
    let_it_be_with_reload(:task1) { create(:work_item, :task, project: project) }
    let_it_be_with_reload(:task2) { create(:work_item, :task, project: project) }
    let_it_be(:guest_task) { create(:work_item, :task) }
    let_it_be(:invalid_task) { build_stubbed(:work_item, :task, id: non_existing_record_id) }
    let_it_be(:another_project) { (create :project) }
    let_it_be(:other_project_task) { create(:work_item, :task, iid: 100, project: another_project) }
    let_it_be(:existing_parent_link) { create(:parent_link, work_item: task, work_item_parent: work_item) }

    let(:parent_link_class) { WorkItems::ParentLink }
    let(:issuable_type) { :task }
    let(:params) { {} }

    before do
      project.add_reporter(user)
      project.add_guest(guest)
      guest_task.project.add_guest(user)
      another_project.add_reporter(user)
    end

    shared_examples 'returns not found error' do
      it 'returns error' do
        error = "No matching work item found. Make sure that you are adding a valid work item ID."

        is_expected.to eq(service_error(error))
      end

      it 'no relationship is created' do
        expect { subject }.not_to change(parent_link_class, :count)
      end
    end

    subject { described_class.new(work_item, user, params).execute }

    context 'when the reference list is empty' do
      let(:params) { { issuable_references: [] } }

      it_behaves_like 'returns not found error'
    end

    context 'when work item not found' do
      let(:params) { { issuable_references: [invalid_task] } }

      it_behaves_like 'returns not found error'
    end

    context 'when user has no permission to link work items' do
      let(:params) { { issuable_references: [guest_task] } }

      it_behaves_like 'returns not found error'
    end

    context 'child and parent are the same work item' do
      let(:params) { { issuable_references: [work_item] } }

      it 'no relationship is created' do
        expect { subject }.not_to change(parent_link_class, :count)
      end
    end

    context 'when adjacent is already in place' do
      using RSpec::Parameterized::TableSyntax

      let_it_be_with_reload(:parent_item) { create(:work_item, :objective, project: project) }
      let_it_be_with_reload(:current_item) { create(:work_item, :objective, project: project) }

      let_it_be_with_reload(:adjacent) do
        create(:work_item, :objective, project: project)
      end

      let_it_be_with_reload(:link_to_adjacent) do
        create(:parent_link, work_item_parent: parent_item, work_item: adjacent)
      end

      subject { described_class.new(parent_item, user, { target_issuable: current_item }).execute }

      where(:adjacent_position, :expected_order) do
        -100 | lazy { [adjacent, current_item] }
        0    | lazy { [adjacent, current_item] }
        100  | lazy { [adjacent, current_item] }
      end

      with_them do
        before do
          link_to_adjacent.update!(relative_position: adjacent_position)
        end

        it 'sets relative positions' do
          expect { subject }.to change(parent_link_class, :count).by(1)
          expect(parent_item.work_item_children_by_relative_position).to eq(expected_order)
        end
      end
    end

    context 'when there are tasks to relate' do
      let(:params) { { issuable_references: [task1, task2] } }

      it_behaves_like 'update service that triggers GraphQL work_item_updated subscription' do
        let(:trigger_call_counter) { 2 }

        subject(:execute_service) { described_class.new(work_item, user, params).execute }
      end

      it 'creates relationships', :aggregate_failures do
        expect { subject }.to change(parent_link_class, :count).by(2)

        tasks_parent = parent_link_class.where(work_item: [task1, task2]).map(&:work_item_parent).uniq
        expect(tasks_parent).to match_array([work_item])
      end

      context 'when relative_position is set' do
        let(:params) { { issuable_references: [task1, task2], relative_position: 1337 } }

        it 'creates relationships with given relative_position' do
          result = subject

          expect(result[:created_references].first.relative_position).to eq(1337)
          expect(result[:created_references].second.relative_position).to eq(1337)
        end
      end

      it 'returns success status and created links', :aggregate_failures do
        expect(subject.keys).to match_array([:status, :created_references])
        expect(subject[:status]).to eq(:success)
        expect(subject[:created_references].map(&:work_item_id)).to match_array([task1.id, task2.id])
      end

      it 'creates notes and records the events', :aggregate_failures do
        expect { subject }.to change(WorkItems::ResourceLinkEvent, :count).by(2)

        work_item_notes = work_item.notes.last(2)
        resource_link_events = WorkItems::ResourceLinkEvent.last(2)
        expect(work_item_notes.first.note).to eq("added #{task1.to_reference} as child task")
        expect(work_item_notes.last.note).to eq("added #{task2.to_reference} as child task")
        expect(task1.notes.last.note).to eq("added #{work_item.to_reference} as parent issue")
        expect(task2.notes.last.note).to eq("added #{work_item.to_reference} as parent issue")
        expect(resource_link_events.first).to have_attributes(
          user_id: user.id,
          issue_id: work_item.id,
          child_work_item_id: task1.id,
          action: "add",
          system_note_metadata_id: task1.notes.last.system_note_metadata.id
        )
        expect(resource_link_events.last).to have_attributes(
          user_id: user.id,
          issue_id: work_item.id,
          child_work_item_id: task2.id,
          action: "add",
          system_note_metadata_id: task2.notes.last.system_note_metadata.id
        )
      end

      context 'when note creation fails for some reason' do
        let(:params) { { issuable_references: [task1] } }

        [Note.new, nil].each do |relate_child_note|
          it 'still records the link event', :aggregate_failures do
            allow_next_instance_of(WorkItems::ParentLinks::CreateService) do |instance|
              allow(instance).to receive(:create_notes).and_return(relate_child_note)
            end

            expect { subject }
              .to change(WorkItems::ResourceLinkEvent, :count).by(1)
              .and not_change(Note, :count)

            expect(WorkItems::ResourceLinkEvent.last).to have_attributes(
              user_id: user.id,
              issue_id: work_item.id,
              child_work_item_id: task1.id,
              action: "add",
              system_note_metadata_id: nil
            )
          end
        end
      end

      context 'when task is already assigned' do
        let(:params) { { issuable_references: [task, task2] } }

        it_behaves_like 'update service that triggers GraphQL work_item_updated subscription' do
          subject(:execute_service) { described_class.new(work_item, user, params).execute }
        end

        it 'creates links only for non related tasks', :aggregate_failures do
          expect { subject }
            .to change(parent_link_class, :count).by(1)
            .and change(WorkItems::ResourceLinkEvent, :count).by(1)

          expect(subject[:created_references].map(&:work_item_id)).to match_array([task2.id])
          expect(work_item.notes.last.note).to eq("added #{task2.to_reference} as child task")
          expect(task2.notes.last.note).to eq("added #{work_item.to_reference} as parent issue")
          expect(task.notes).to be_empty
          expect(WorkItems::ResourceLinkEvent.last).to have_attributes(
            user_id: user.id,
            issue_id: work_item.id,
            child_work_item_id: task2.id,
            action: "add",
            system_note_metadata_id: task2.notes.last.system_note_metadata.id
          )
        end
      end

      context 'when there are invalid children' do
        let_it_be(:issue) { create(:work_item, project: project) }

        let(:params) { { issuable_references: [task1, issue, other_project_task] } }

        it 'creates links only for valid children' do
          expect { subject }.to change { parent_link_class.count }.by(2)
        end

        it 'does not return error status' do
          error = "#{issue.to_reference} cannot be added: is not allowed to add this type of parent. " \
            "#{other_project_task.to_reference} cannot be added: parent must be in the same project or group as child."

          is_expected.not_to eq(service_error(error, http_status: 422))
        end

        it 'creates notes for valid links', :aggregate_failures do
          subject

          expect(work_item.notes.last.note).to eq("added #{other_project_task.to_reference(full: true)} as child task")
          expect(task1.notes.last.note).to eq("added #{work_item.to_reference} as parent issue")
          expect(issue.notes).to be_empty
          expect(other_project_task.notes).not_to be_empty
        end
      end

      context 'when parent type is invalid' do
        let(:work_item) { create :work_item, :task, project: project }

        let(:params) { { target_issuable: task1 } }

        it 'returns error status' do
          error = "#{task1.to_reference} cannot be added: is not allowed to add this type of parent"

          is_expected.to eq(service_error(error, http_status: 422))
        end
      end

      context 'when max depth is reached' do
        let(:params) { { issuable_references: [task2] } }

        before do
          stub_const("#{parent_link_class}::MAX_CHILDREN", 1)
        end

        it 'returns error status' do
          error = "#{task2.to_reference} cannot be added: parent already has maximum number of children."

          is_expected.to eq(service_error(error, http_status: 422))
        end
      end

      context 'when params include invalid ids' do
        let(:params) { { issuable_references: [task1, guest_task] } }

        it 'creates links only for valid IDs' do
          expect { subject }.to change(parent_link_class, :count).by(1)
        end
      end

      context 'when user is a guest' do
        let(:user) { guest }

        it_behaves_like 'returns not found error'
      end

      context 'when user is a guest assigned to the work item' do
        let(:user) { guest }

        before do
          work_item.assignees = [guest]
        end

        it_behaves_like 'returns not found error'
      end
    end
  end

  def service_error(message, http_status: 404)
    {
      message: message,
      status: :error,
      http_status: http_status
    }
  end
end
