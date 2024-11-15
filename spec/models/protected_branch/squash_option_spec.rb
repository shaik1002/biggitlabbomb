# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranch::SquashOption, type: :model, feature_category: :source_code_management do
  describe 'Associations' do
    it { is_expected.to belong_to(:protected_branch) }
  end

  describe 'Validations' do
    let(:squash_option) { build :squash_option }

    it { is_expected.to validate_presence_of(:protected_branch) }

    context 'when protected branch is present' do
      let(:squash_option) { build(:squash_option, protected_branch: protected_branch) }
      let(:protected_branch) { build(:protected_branch, name: 'main') }

      context 'when protected branch is wildcard' do
        let(:protected_branch) { build(:protected_branch, name: '*') }

        it 'has validation errors regarding the wildcard' do
          expect(squash_option).not_to be_valid
          expect(squash_option.errors.full_messages).to include('cannot configure squash options for wildcard')
        end
      end
    end
  end
end
