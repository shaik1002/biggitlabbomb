# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DestroyOldPipelinesWorker, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, ci_delete_pipelines_in_seconds: 2.weeks.to_i) }
  let_it_be(:ancient_pipeline) { create(:ci_pipeline, project: project, created_at: 1.year.ago) }
  let_it_be(:old_pipeline) { create(:ci_pipeline, project: project, created_at: 1.month.ago) }
  let_it_be(:new_pipeline) { create(:ci_pipeline, project: project, created_at: 1.week.ago) }

  describe '#perform' do
    subject(:perform) { described_class.new.perform(project.id) }

    it 'destroys the configured amount of pipelines' do
      stub_const("#{described_class.name}::LIMIT", 1)

      expect { perform }.to change { project.all_pipelines.count }.by(-1)
      expect(new_pipeline.reload).to be_present
    end

    it 'loops thought the available pipelines' do
      stub_const("#{described_class.name}::LIMIT", 3)

      expect { perform }.to change { project.all_pipelines.count }.by(-2)
      expect(new_pipeline.reload).to be_present
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [project.id] }

      it 'executes the service' do
        expect { perform }.not_to raise_error
      end
    end
  end
end
