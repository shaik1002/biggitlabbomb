# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UpdateSbomOccurrencesComponentNameBasedOnPep503, feature_category: :software_composition_analysis do
  let(:occurrences) { table(:sbom_occurrences) }
  let(:components) { table(:sbom_components) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:namespace) { namespaces.create!(name: 'name', path: 'path') }
  let(:project) { projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }

  describe '#perform' do
    subject(:perform_migration) do
      described_class.new(
        start_id: occurrences.first.id,
        end_id: occurrences.last.id,
        batch_table: :sbom_occurrences,
        batch_column: :id,
        sub_batch_size: occurrences.count,
        pause_ms: 0,
        connection: ActiveRecord::Base.connection
      ).perform
    end

    context 'without data' do
      before do
        component = components.create!(name: 'azure', purl_type: 8, component_type: 0)
        occurrences.create!(project_id: project.id, component_id: component.id, commit_sha: 'commit_sha',
          uuid: SecureRandom.uuid, component_name: 'azure')
      end

      it 'does not raise exception' do
        expect { perform_migration }.not_to raise_error
      end
    end

    context 'with data' do
      before do
        %w[aws-cdk.region-info azure.identity backports.cached-property backports.csv].each do |input_name|
          component = components.create!(name: input_name, purl_type: 8, component_type: 0)
          occurrences.create!(project_id: project.id, component_id: component.id, commit_sha: 'commit_sha',
            uuid: SecureRandom.uuid, component_name: input_name)
        end
      end

      let(:expected_names) { %w[aws-cdk-region-info azure-identity backports-cached-property backports-csv] }

      it 'successfully updates name according to PEP 0503' do
        perform_migration

        expect(occurrences.pluck(:component_name)).to eq(expected_names)
      end

      context 'with unrelated components' do
        let(:component_name) { 'unrelated.component' }
        let(:unrelated_component) { components.create!(name: component_name, purl_type: 6, component_type: 0) }
        let!(:unrelated_occurrence) do
          occurrences.create!(project_id: project.id, component_id: unrelated_component.id, commit_sha: 'commit_sha',
            uuid: SecureRandom.uuid, component_name: component_name)
        end

        it 'does not update the unrelated occurrence' do
          expect { perform_migration }.not_to change { unrelated_occurrence.reload.component_name }
        end
      end
    end
  end
end
