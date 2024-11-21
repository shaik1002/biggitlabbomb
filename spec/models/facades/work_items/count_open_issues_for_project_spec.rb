# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::CountOpenIssuesForProject, feature_category: :team_planning do
  let(:project) { instance_double(Project) }
  let(:current_user) { instance_double(User) }
  let(:facade) { described_class.new(project: project) }
  let(:issues_count_service) { instance_double(WorkItems::ProjectCountOpenIssuesService) }

  before do
    allow(WorkItems::ProjectCountOpenIssuesService).to receive(:new).with(project,
      current_user).and_return(issues_count_service)
    allow(WorkItems::ProjectCountOpenIssuesService).to receive(:new).and_return(issues_count_service)
    allow(issues_count_service).to receive(:refresh_cache)
  end

  describe '#count' do
    it 'retrieves the open issues count for the project' do
      allow(issues_count_service).to receive(:count).and_return(42)
      expect(facade.count(current_user)).to eq(42)
    end
  end

  describe '#refresh_cache' do
    it 'refreshes the cache for open issues count' do
      expect(issues_count_service).to receive(:refresh_cache)
      facade.refresh_cache
    end
  end
end
