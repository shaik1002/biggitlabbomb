# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Ml::ModelVersionsController, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:another_project) { create(:project) }
  let_it_be(:user) { project.first_owner }
  let_it_be(:model) { create(:ml_models, :with_versions, project: project) }
  let_it_be(:version) { model.versions.first }

  let(:model_registry_enabled) { true }

  before do
    allow(Ability).to receive(:allowed?).and_call_original
    allow(Ability).to receive(:allowed?)
                        .with(user, :read_model_registry, project)
                        .and_return(model_registry_enabled)

    sign_in(user)
  end

  describe 'show' do
    let(:model_id) { model.id }
    let(:version_id) { version.id }
    let(:request_project) { model.project }

    subject(:show_request) do
      show_model_version
      response
    end

    before do
      show_request
    end

    it 'renders the template' do
      is_expected.to render_template('projects/ml/model_versions/show')
    end

    it 'fetches the correct model_version' do
      show_request

      expect(assigns(:model)).to eq(model)
      expect(assigns(:model_version)).to eq(version)
    end

    context 'when version id does not exist' do
      let(:version_id) { non_existing_record_id }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when version and model id are correct but project is not' do
      let(:request_project) { another_project }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when user does not have access' do
      let(:model_registry_enabled) { false }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end
  end

  private

  def show_model_version
    get project_ml_model_version_path(request_project, model_id, version_id)
  end
end
