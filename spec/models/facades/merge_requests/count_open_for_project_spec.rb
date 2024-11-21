# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::CountOpenForProject, feature_category: :code_review_workflow do
  let(:project) { instance_double(Project) }
  let(:facade) { described_class.new(project: project) }
  let(:merge_requests_count_service) { instance_double(MergeRequests::BatchCountOpenService) }

  before do
    allow(MergeRequests::BatchCountOpenService).to receive(:new).with([project])
      .and_return(merge_requests_count_service)
  end

  describe '#call' do
    it 'retrieves and loads open merge requests count data for the project using BatchLoader' do
      allow(merge_requests_count_service).to receive(:refresh_cache_and_retrieve_data).and_return({ project => 3 })
      expect(facade.call).to eq(3)
    end
  end
end
