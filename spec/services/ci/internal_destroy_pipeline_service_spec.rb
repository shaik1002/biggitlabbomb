# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::InternalDestroyPipelineService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }

  let!(:pipeline) { create(:ci_pipeline, :success, project: project, sha: project.commit.id) }

  subject(:destroy_service) { described_class.new(pipeline).execute }

  it 'destroys the pipeline' do
    destroy_service

    expect { pipeline.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'clears the cache', :use_clean_rails_redis_caching do
    create(:commit_status, :success, pipeline: pipeline, ref: pipeline.ref)

    expect(project.pipeline_status.has_status?).to be_truthy

    destroy_service

    # We need to reset lazy_latest_pipeline cache to simulate a new request
    BatchLoader::Executor.clear_current

    # Need to use find to avoid memoization
    expect(Project.find(project.id).pipeline_status.has_status?).to be_falsey
  end

  it 'does not log an audit event' do
    expect { destroy_service }.not_to change { AuditEvent.count }
  end

  context 'when the pipeline has jobs' do
    let!(:build) { create(:ci_build, project: project, pipeline: pipeline) }

    it 'destroys associated jobs' do
      destroy_service

      expect { build.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'destroys associated stages' do
      stages = pipeline.stages

      destroy_service

      expect(stages).to all(raise_error(ActiveRecord::RecordNotFound))
    end

    context 'when job has artifacts' do
      let!(:artifact) { create(:ci_job_artifact, :archive, job: build) }

      it 'destroys associated artifacts' do
        destroy_service

        expect { artifact.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'inserts deleted objects for object storage files' do
        expect { destroy_service }.to change { Ci::DeletedObject.count }
      end
    end

    context 'when job has trace chunks' do
      let(:connection_params) { Gitlab.config.artifacts.object_store.connection.symbolize_keys }
      let(:connection) { ::Fog::Storage.new(connection_params) }
      let(:trace_chunk) { create(:ci_build_trace_chunk, :fog_with_data, build: build) }

      before do
        stub_object_storage(connection_params: connection_params, remote_directory: 'artifacts')
        stub_artifacts_object_storage

        trace_chunk
      end

      it 'destroys associated trace chunks' do
        destroy_service

        expect { trace_chunk.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'removes data from object store' do
        expect { destroy_service }.to change { Ci::BuildTraceChunks::Fog.new.data(trace_chunk) }
      end
    end
  end

  context 'when pipeline is in cancelable state', :sidekiq_inline do
    let!(:build) { create(:ci_build, :running, pipeline: pipeline) }
    let!(:child_pipeline) { create(:ci_pipeline, :running, child_of: pipeline) }
    let!(:child_build) { create(:ci_build, :running, pipeline: child_pipeline) }

    it 'cancels the pipelines sync' do
      cancel_pipeline_service = instance_double(::Ci::CancelPipelineService)
      expect(::Ci::CancelPipelineService)
        .to receive(:new)
        .with(pipeline: pipeline, current_user: nil, cascade_to_children: true, execute_async: false)
        .and_return(cancel_pipeline_service)

      expect(cancel_pipeline_service).to receive(:force_execute)

      destroy_service
    end
  end
end
