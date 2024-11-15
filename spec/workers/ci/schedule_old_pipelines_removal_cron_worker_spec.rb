# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ScheduleOldPipelinesRemovalCronWorker,
  :clean_gitlab_redis_shared_state, feature_category: :continuous_integration do
  let(:worker) { described_class.new }

  let_it_be(:project) { create(:project, ci_delete_pipelines_in_seconds: 2.weeks.to_i) }

  it { is_expected.to include_module(CronjobQueue) }
  it { expect(described_class.idempotent?).to be_truthy }

  describe '#perform' do
    it 'enqueues DestroyOldPipelinesWorker jobs' do
      expect(Ci::DestroyOldPipelinesWorker).to receive(:bulk_perform_in).with(3.seconds, [[project.id]])

      worker.perform
    end

    context 'when the worker reaches the maximum number of batches' do
      before do
        stub_const("#{described_class}::ITERATIONS", 1)
      end

      it 'sets the last processed record id in Redis cache' do
        worker.perform

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.get(described_class::LAST_PROCESSED_REDIS_KEY).to_i).to eq(project.ci_cd_settings.id)
        end
      end
    end

    context 'when the worker continues processing from previous execution' do
      let_it_be(:other_project) { create(:project, ci_delete_pipelines_in_seconds: 2.weeks.to_i) }

      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.set(described_class::LAST_PROCESSED_REDIS_KEY, other_project.ci_cd_settings.id)
        end
      end

      it 'enqueues DestroyOldPipelinesWorker jobs' do
        expect(Ci::DestroyOldPipelinesWorker).to receive(:bulk_perform_in).with(3.seconds, [[other_project.id]])

        worker.perform
      end
    end

    context 'when the worker finishes processing before running out of batches' do
      before do
        stub_const("#{described_class}::ITERATIONS", 2)

        Gitlab::Redis::SharedState.with do |redis|
          redis.set(described_class::LAST_PROCESSED_REDIS_KEY, 0)
        end
      end

      it 'clears the last processed record id in Redis cache' do
        worker.perform

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.get(described_class::LAST_PROCESSED_REDIS_KEY)).to be_nil
        end
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(ci_delete_old_pipelines: false)
      end

      it 'does not enqueue DestroyOldPipelinesWorker jobs' do
        expect(Ci::DestroyOldPipelinesWorker).not_to receive(:bulk_perform_in)

        worker.perform
      end
    end
  end
end
