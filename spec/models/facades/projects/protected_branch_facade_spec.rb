# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProtectedBranchFacade, feature_category: :source_code_management do
  let(:project) { instance_double(Project) }
  let(:cache_service) { instance_double(ProtectedBranches::CacheService) }
  let(:ref_name) { 'some_branch' }
  let(:facade) { described_class.new(project: project) }

  before do
    allow(ProtectedBranches::CacheService).to receive(:new).and_return(cache_service)
  end

  describe '#protected?' do
    context 'when unprotected' do
      before do
        allow(project).to receive_messages(
          empty_repo?: true,
          default_branch_protected?: false
        )
        allow(cache_service).to receive(:fetch).with('some_branch').and_return(false)
      end

      it 'checks if the branch is protected when cache service is used' do
        # Hier kannst du auch das Stubben von `cache_service.fetch` und der Methode `branch_protected?` machen
        expect(facade.protected?(ref_name)).to be_falsey
      end
    end

    context 'when protected' do
      before do
        allow(project).to receive_messages(
          empty_repo?: true,
          default_branch_protected?: true
        )
      end

      it 'checks if the branch is protected when cache service is used' do
        # Hier kannst du auch das Stubben von `cache_service.fetch` und der Methode `branch_protected?` machen
        expect(facade.protected?(ref_name)).to be_truthy
      end
    end
  end
end
