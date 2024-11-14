# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::AuthorizedBuildService, feature_category: :user_management do
  describe '#execute' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:organization) { create(:organization) }

    let(:base_params) do
      build_stubbed(:user)
        .slice(:first_name, :last_name, :name, :username, :email, :password)
        .merge(organization_id: organization.id)
    end

    let(:params) { base_params }

    subject(:user) { described_class.new(current_user, params).execute }

    it_behaves_like 'common user build items'
    it_behaves_like 'current user not admin build items'

    context 'for additional authorized build allowed params' do
      before do
        params.merge!(external: true)
      end

      it { expect(user).to be_external }
    end
  end
end
