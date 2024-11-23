# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::TagProtection::Rule, type: :model, feature_category: :container_registry do
  it_behaves_like 'having unique enum values'

  describe 'relationships' do
    it { is_expected.to belong_to(:project).inverse_of(:container_registry_tag_protection_rules) }
  end

  describe 'enums' do
    it 'defines an enum for minimum access level for push' do
      is_expected.to(
        define_enum_for(:minimum_access_level_for_push)
          .with_values(
            maintainer: Gitlab::Access::MAINTAINER,
            owner: Gitlab::Access::OWNER,
            admin: Gitlab::Access::ADMIN
          )
          .with_prefix(:minimum_access_level_for_push)
      )
    end

    it 'defines an enum for minimum access level for delete' do
      is_expected.to(
        define_enum_for(:minimum_access_level_for_delete)
        .with_values(
          maintainer: Gitlab::Access::MAINTAINER,
          owner: Gitlab::Access::OWNER,
          admin: Gitlab::Access::ADMIN
        )
        .with_prefix(:minimum_access_level_for_delete)
      )
    end
  end

  describe 'validations' do
    subject { build(:container_registry_tag_protection_rule) }

    describe '#tag_name_pattern' do
      it { is_expected.to validate_presence_of(:tag_name_pattern) }
      it { is_expected.to validate_length_of(:tag_name_pattern).is_at_most(100) }
      it { is_expected.to validate_presence_of(:minimum_access_level_for_delete) }
      it { is_expected.to validate_presence_of(:minimum_access_level_for_push) }
      it { is_expected.to validate_uniqueness_of(:tag_name_pattern).scoped_to(:project_id) }
    end
  end
end
