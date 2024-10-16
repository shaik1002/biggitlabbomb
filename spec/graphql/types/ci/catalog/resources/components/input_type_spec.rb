# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::Catalog::Resources::Components::InputType, feature_category: :pipeline_composition do
  specify { expect(described_class.graphql_name).to eq('CiCatalogResourceComponentInput') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      name
      default
      required
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
