# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::ModelVersionPresenter, feature_category: :mlops do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:model) { build_stubbed(:ml_models, name: 'a_model', project: project) }
  let_it_be(:model_version) { build_stubbed(:ml_model_versions, :with_package, model: model, version: '1.1.1') }
  let_it_be(:presenter) { model_version.present }

  describe '.display_name' do
    subject { presenter.display_name }

    it { is_expected.to eq('a_model / 1.1.1') }
  end

  describe '#path' do
    subject { presenter.path }

    it { is_expected.to eq("/#{project.full_path}/-/ml/models/#{model.id}/versions/#{model_version.id}") }
  end

  describe '#package_path' do
    subject { presenter.package_path }

    it { is_expected.to eq("/#{project.full_path}/-/packages/#{model_version.package_id}") }
  end
end
