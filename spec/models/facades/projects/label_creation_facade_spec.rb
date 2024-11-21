# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::LabelCreationFacade, feature_category: :team_planning do
  let(:project) { instance_double(Project) }
  let(:facade) { described_class.new(project: project) }
  let(:label_service) { instance_double(Labels::FindOrCreateService) }
  let(:label_template) { instance_double(Label, attributes: { name: 'bug', color: 'red' }) }

  before do
    allow(Label).to receive(:templates).and_return([label_template])
    allow(Labels::FindOrCreateService).to receive(:new).and_return(label_service)
    allow(label_service).to receive(:execute)
  end

  describe '#call' do
    it 'creates labels from templates' do
      expect(label_service).to receive(:execute).with(skip_authorization: true)
      facade.call
    end
  end
end
