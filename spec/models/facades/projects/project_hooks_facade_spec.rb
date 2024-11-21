# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProjectHooksFacade, feature_category: :integrations do
  let(:project) { instance_double(Project) }
  let(:facade) { described_class.new(project: project) }
  let(:data) { { some: 'data' } }
  let(:hooks_scope) { :push_hooks }
  let(:system_hooks_service) { instance_double(SystemHooksService) }

  before do
    allow(SystemHooksService).to receive(:new).and_return(system_hooks_service)
    allow(system_hooks_service).to receive(:execute_hooks)
    allow(project).to receive_message_chain(:triggered_hooks, :execute)
  end

  describe '#call' do
    it 'executes the project and system hooks' do
      expect(system_hooks_service).to receive(:execute_hooks).with(data, hooks_scope)
      facade.call(data, hooks_scope)
    end
  end
end
