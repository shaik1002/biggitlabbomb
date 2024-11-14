# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Current, feature_category: :cell do
  after do
    described_class.reset
  end

  describe '.organization=' do
    context 'when organization has not been set yet' do
      where(:value) do
        [nil, '_value_']
      end

      with_them do
        it 'assigns the value and locks the organization setter' do
          expect do
            described_class.organization = value
          end.to change { described_class.lock_organization }.from(nil).to(true)

          expect(described_class.organization).to eq(value)
        end
      end
    end

    context 'when organization has already been set' do
      it 'assigns the value and locks the organization setter' do
        set_value = '_set_value_'

        described_class.organization = set_value

        expect(described_class.lock_organization).to be(true)
        expect(described_class.organization).to eq(set_value)

        expect do
          described_class.organization = '_new_value_'
        end.to raise_error(ArgumentError)

        expect(described_class.organization).to eq(set_value)
      end

      context 'when not raise outside of dev/test environments' do
        before do
          stub_rails_env('production')
        end

        it 'returns silently without changing value' do
          set_value = '_set_value_'

          described_class.organization = set_value

          expect { described_class.organization = '_new_value_' }.not_to raise_error

          expect(described_class.organization).to eq(set_value)
        end
      end
    end
  end

  describe '.organization_id' do
    let_it_be(:current_organization) { create(:organization) }

    subject(:organization_id) { described_class.organization_id }

    context 'when organization is set' do
      before do
        described_class.organization = current_organization
      end

      it 'returns the id of the organization' do
        expect(organization_id).not_to be_nil
        expect(organization_id).to eq(current_organization.id)
      end
    end

    context 'when organization is not set' do
      it 'returns nil' do
        expect(organization_id).to be_nil
      end
    end
  end
end
