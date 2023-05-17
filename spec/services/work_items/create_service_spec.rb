# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::CreateService, feature_category: :team_planning do
  include AfterNextHelpers

  RSpec.shared_examples 'creates work item in container' do |container_type|
    let_it_be_with_reload(:project) { create(:project) }
    let_it_be_with_reload(:group) { create(:group) }

    let_it_be(:container) do
      case container_type
      when :project then project
      when :project_namespace then project.project_namespace
      when :group then group
      end
    end

    let_it_be(:container_args) do
      case container_type
      when :project, :project_namespace then { project: project }
      when :group then { namespace: group }
      end
    end

    let_it_be(:parent) { create(:work_item, **container_args) }
    let_it_be(:guest) { create(:user) }
    let_it_be(:reporter) { create(:user) }
    let_it_be(:user_with_no_access) { create(:user) }

    let(:widget_params) { {} }
    let(:spam_params) { double }
    let(:current_user) { guest }
    let(:opts) do
      {
        title: 'Awesome work_item',
        description: 'please fix'
      }
    end

    before_all do
      memberships_container = container.is_a?(Namespaces::ProjectNamespace) ? container.reload.project : container
      memberships_container.add_guest(guest)
      memberships_container.add_reporter(reporter)
    end

    describe '#execute' do
      shared_examples 'fails creating work item and returns errors' do
        it 'does not create new work item if parent can not be set' do
          expect { service_result }.not_to change(WorkItem, :count)

          expect(service_result[:status]).to be(:error)
          expect(service_result[:message]).to match(error_message)
        end
      end

      let(:service) do
        described_class.new(
          container: container,
          current_user: current_user,
          params: opts,
          spam_params: spam_params,
          widget_params: widget_params
        )
      end

      subject(:service_result) { service.execute }

      before do
        stub_spam_services
      end

      context 'when user is not allowed to create a work item in the container' do
        let(:current_user) { user_with_no_access }

        it { is_expected.to be_error }

        it 'returns an access error' do
          expect(service_result.errors).to contain_exactly('Operation not allowed')
        end
      end

      context 'when applying quick actions' do
        let(:work_item) { service_result[:work_item] }
        let(:opts) do
          {
            title: 'My work item',
            work_item_type: work_item_type,
            description: '/shrug'
          }
        end

        context 'when work item type is not the default Issue' do
          let(:work_item_type) { create(:work_item_type, :task, namespace: group) }

          it 'saves the work item without applying the quick action' do
            expect(service_result).to be_success
            expect(work_item).to be_persisted
            expect(work_item.description).to eq('/shrug')
          end
        end

        context 'when work item type is the default Issue' do
          let(:work_item_type) { WorkItems::Type.default_by_type(:issue) }

          it 'saves the work item and applies the quick action' do
            expect(service_result).to be_success
            expect(work_item).to be_persisted
            expect(work_item.description).to eq(' ¯\＿(ツ)＿/¯')
          end
        end
      end

      context 'when params are valid' do
        it 'created instance is a WorkItem' do
          expect(Issuable::CommonSystemNotesService).to receive_message_chain(:new, :execute)

          work_item = service_result[:work_item]

          expect(work_item).to be_persisted
          expect(work_item).to be_a(::WorkItem)
          expect(work_item.title).to eq('Awesome work_item')
          expect(work_item.description).to eq('please fix')
          expect(work_item.work_item_type.base_type).to eq('issue')
        end

        it 'calls NewIssueWorker with correct arguments' do
          expect(NewIssueWorker).to receive(:perform_async).with(Integer, current_user.id, 'WorkItem')

          service_result
        end
      end

      context 'when params are invalid' do
        let(:opts) { { title: '' } }

        it { is_expected.to be_error }

        it 'returns validation errors' do
          expect(service_result.errors).to contain_exactly("Title can't be blank")
        end

        it 'does not execute after-create transaction widgets' do
          expect(service).to receive(:create).and_call_original
          expect(service).not_to receive(:execute_widgets)
                                   .with(callback: :after_create_in_transaction, widget_params: widget_params)

          service_result
        end
      end

      context 'checking spam' do
        it 'executes SpamActionService' do
          expect_next_instance_of(
            Spam::SpamActionService,
            {
              spammable: kind_of(WorkItem),
              spam_params: spam_params,
              user: an_instance_of(User),
              action: :create
            }
          ) do |instance|
            expect(instance).to receive(:execute)
          end

          service_result
        end
      end

      it_behaves_like 'work item widgetable service' do
        let(:widget_params) do
          {
            hierarchy_widget: { parent: parent }
          }
        end

        let(:service) do
          described_class.new(
            container: container,
            current_user: current_user,
            params: opts,
            spam_params: spam_params,
            widget_params: widget_params
          )
        end

        let(:service_execute) { service.execute }

        let(:supported_widgets) do
          [
            {
              klass: WorkItems::Widgets::HierarchyService::CreateService,
              callback: :after_create_in_transaction,
              params: { parent: parent }
            }
          ]
        end
      end

      describe 'hierarchy widget' do
        let(:widget_params) { { hierarchy_widget: { parent: parent } } }

        context 'when user can admin parent link' do
          let(:current_user) { reporter }

          context 'when parent is valid work item' do
            let(:opts) do
              {
                title: 'Awesome work_item',
                description: 'please fix',
                work_item_type: WorkItems::Type.default_by_type(:task)
              }
            end

            it 'creates new work item and sets parent reference' do
              expect { service_result }.to change(WorkItem, :count).by(1).and(
                change(WorkItems::ParentLink, :count).by(1)
              )

              expect(service_result[:status]).to be(:success)
            end
          end

          context 'when parent type is invalid' do
            let_it_be(:parent) { create(:work_item, :task, **container_args) }

            it_behaves_like 'fails creating work item and returns errors' do
              let(:error_message) { 'is not allowed to add this type of parent' }
            end
          end
        end

        context 'when user cannot admin parent link' do
          let(:current_user) { guest }

          let(:opts) do
            {
              title: 'Awesome work_item',
              description: 'please fix',
              work_item_type: WorkItems::Type.default_by_type(:task)
            }
          end

          it_behaves_like 'fails creating work item and returns errors' do
            let(:error_message) { 'No matching work item found. Make sure that you are adding a valid work item ID.' }
          end
        end
      end
    end
  end

  it_behaves_like 'creates work item in container', :project
  it_behaves_like 'creates work item in container', :project_namespace
  it_behaves_like 'creates work item in container', :group
end
