# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::AuthorizationsCompactor, feature_category: :secrets_management do
  let_it_be(:accessed_project) { create(:project) }
  let(:compactor) { described_class.new(accessed_project.id) }

  # [1, 21],            ns1, p1
  # [1, 2, 3],          ns1, ns2, p2
  # [1, 2, 4],          ns1, ns2, p3
  # [1, 2, 5],          ns1, ns2, p4
  # [1, 2, 12, 13],     ns1, ns2, ns3, p5
  # [1, 6, 7],          ns1, ns4, p6
  # [1, 6, 8],          ns1, ns4, p7
  # [9, 10, 11]         ns5, ns6, p8

  let_it_be(:ns1) { create(:group, name: 'ns1') }
  let_it_be(:ns2) { create(:group, parent: ns1, name: 'ns2') }
  let_it_be(:ns3) { create(:group, parent: ns2, name: 'ns3') }
  let_it_be(:ns4) { create(:group, parent: ns1, name: 'ns4') }
  let_it_be(:ns5) { create(:group, name: 'ns5') }
  let_it_be(:ns6) { create(:group, parent: ns5, name: 'ns6') }

  let_it_be(:pns1) { create(:project_namespace, parent: ns1) }
  let_it_be(:pns2) { create(:project_namespace, parent: ns2) }
  let_it_be(:pns3) { create(:project_namespace, parent: ns2) }
  let_it_be(:pns4) { create(:project_namespace, parent: ns2) }
  let_it_be(:pns5) { create(:project_namespace, parent: ns3) }
  let_it_be(:pns6) { create(:project_namespace, parent: ns4) }
  let_it_be(:pns7) { create(:project_namespace, parent: ns4) }
  let_it_be(:pns8) { create(:project_namespace, parent: ns6) }

  before do
    origin_project_namespaces = [
      pns1, pns2, pns3, pns4, pns5, pns6, pns7, pns8
    ]

    origin_project_namespaces.each do |project_namespace|
      create(:ci_job_token_authorization, origin_project: project_namespace.project, accessed_project: accessed_project,
        last_authorized_at: 1.day.ago)
    end
  end

  describe '#compact' do
    it 'compacts the allowlist groups and projects as expected for the given limit' do
      compactor.compact(4)

      expect(compactor.allowlist_groups).to match_array([ns2, ns4])
      expect(compactor.allowlist_projects).to match_array([pns1.project, pns8.project])
    end

    it 'compacts the allowlist groups and projects as expected for the given limit' do
      compactor.compact(3)

      expect(compactor.allowlist_groups).to match_array([ns1])
      expect(compactor.allowlist_projects).to match_array([pns8.project])
    end

    it 'raises when the limit cannot be achieved' do
      expect do
        compactor.compact(1)
      end.to raise_error(Gitlab::Utils::TraversalIdCompactor::CompactionLimitCannotBeAchievedError)
    end

    it 'raises when an unexpected compaction entry is found' do
      allow(Gitlab::Utils::TraversalIdCompactor).to receive(:compact).and_wrap_original do |original_method, *args|
        original_response = original_method.call(*args)
        original_response << [1, 2, 3]
      end

      expect { compactor.compact(5) }.to raise_error(described_class::UnexpectedCompactionEntry)
    end

    it 'raises when a redundant compaction entry is found' do
      allow(Gitlab::Utils::TraversalIdCompactor).to receive(:compact).and_wrap_original do |original_method, *args|
        original_response = original_method.call(*args)
        original_response << original_response.last.first(2)
      end

      expect { compactor.compact(5) }.to raise_error(described_class::RedundantCompactionEntry)
    end
  end
end
