# frozen_string_literal: true

require 'rspec'

require 'spec_helper'
require 'mime/types'

RSpec.describe Projects::Ml::ModelRegistryHelper, feature_category: :mlops do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:user) { project.owner }

  describe '#index_ml_model_data' do
    subject(:parsed) { Gitlab::Json.parse(helper.index_ml_model_data(project, user)) }

    it 'generates the correct data' do
      is_expected.to eq({
        'projectPath' => project.full_path,
        'createModelPath' => "/#{project.full_path}/-/ml/models/new",
        'canWriteModelRegistry' => true,
        'mlflowTrackingUrl' => "http://localhost/api/v4/projects/#{project.id}/ml/mlflow/"
      })
    end

    context 'when user does not have write access to model registry' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
                            .with(user, :write_model_registry, project)
                            .and_return(false)
      end

      it 'canWriteModelRegistry is false' do
        expect(parsed['canWriteModelRegistry']).to eq(false)
      end
    end
  end

  describe '#show_ml_model_data' do
    let_it_be(:model) do
      build_stubbed(:ml_models, project: project, name: 'cool_model')
    end

    subject(:parsed) { Gitlab::Json.parse(helper.show_ml_model_data(model, user)) }

    it 'generates the correct data' do
      is_expected.to eq({
        'projectPath' => project.full_path,
        'indexModelsPath' => "/#{project.full_path}/-/ml/models",
        'canWriteModelRegistry' => true,
        'mlflowTrackingUrl' => "http://localhost/api/v4/projects/#{project.id}/ml/mlflow/",
        'modelId' => model.id,
        'modelName' => 'cool_model'
      })
    end

    context 'when user does not have write access to model registry' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
                            .with(user, :write_model_registry, project)
                            .and_return(false)
      end

      it 'canWriteModelRegistry is false' do
        expect(parsed['canWriteModelRegistry']).to eq(false)
      end
    end
  end

  describe '#show_ml_model_version_data' do
    let_it_be(:model) do
      build_stubbed(:ml_models, :with_latest_version_and_package, project: project, id: 1)
    end

    let_it_be(:model_version) do
      model.latest_version
    end

    subject(:parsed) { Gitlab::Json.parse(helper.show_ml_model_version_data(model_version, user)) }

    it 'generates the correct data' do
      is_expected.to eq({
        "projectPath" => project.full_path,
        "modelId" => model.id,
        "modelVersionId" => model_version.id,
        "modelName" => model_version.name,
        "versionName" => model_version.version,
        "canWriteModelRegistry" => true
      })
    end

    context 'when user does not have write access to model registry' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
                            .with(user, :write_model_registry, project)
                            .and_return(false)
      end

      it 'canWriteModelRegistry is false' do
        expect(parsed['canWriteModelRegistry']).to eq(false)
      end
    end
  end
end
