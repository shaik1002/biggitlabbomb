# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProtectDefaultBranchFacade, feature_category: :source_code_management do
  let(:project) { instance_double(Project) }
  let(:facade) { described_class.new(project: project) }
  let(:protect_service) { instance_double(Projects::ProtectDefaultBranchService) }

  before do
    allow(Projects::ProtectDefaultBranchService).to receive(:new).with(project).and_return(protect_service)
    allow(protect_service).to receive(:execute)
  end

  describe '#call' do
    it 'protects the default branch' do
      expect(protect_service).to receive(:execute)
      facade.call
    end
  end
end
