# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BatchForksCountFacade, feature_category: :source_code_management do
  let(:project) { instance_double(Project) }
  let(:facade) { described_class.new(project: project) }
  let(:fork_count_service) { instance_double(::Projects::BatchForksCountService) }
  let(:fork_counts) { { project => 5 } }

  before do
    allow(::Projects::BatchForksCountService).to receive(:new).with([project]).and_return(fork_count_service)
    allow(fork_count_service).to receive(:refresh_cache_and_retrieve_data).and_return(fork_counts)
  end

  describe '#call' do
    it 'loads fork count data for the project using BatchLoader' do
      expect(facade.call).to eq(5)
    end
  end
end
