# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::GroupsController, feature_category: :cell do
  let_it_be(:organization) { create(:organization) }

  describe 'GET #new' do
    subject(:gitlab_request) { get new_groups_organization_path(organization) }

    context 'when the user is not signed in' do
      it_behaves_like 'organization - redirects to sign in page'

      context 'when `ui_for_organizations` feature flag is disabled' do
        before do
          stub_feature_flags(ui_for_organizations: false)
        end

        it_behaves_like 'organization - redirects to sign in page'
      end
    end

    context 'when the user is signed in' do
      let_it_be(:user) { create(:user) }

      before do
        sign_in(user)
      end

      context 'with no association to an organization' do
        it_behaves_like 'organization - not found response'
        it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
      end

      context 'as as admin', :enable_admin_mode do
        let_it_be(:user) { create(:admin) }

        it_behaves_like 'organization - successful response'
        it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
      end

      context 'as an organization user' do
        let_it_be(:organization_user) { create(:organization_user, organization: organization, user: user) }

        it_behaves_like 'organization - successful response'
        it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
      end
    end
  end

  describe 'POST #create' do
    let_it_be(:params) { { group: { name: 'test-group', path: 'test-group' } } }
    let_it_be(:user) { create(:user) }
    let_it_be(:organization) { create(:organization) }

    subject(:gitlab_request) { post groups_organization_path(organization), params: params, as: :json }

    context 'when the user is signed in' do
      before do
        sign_in(user)
      end

      it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'

      context 'when current user can create group inside the organization' do
        let_it_be(:organization_user) { create(:organization_user, organization: organization, user: user) }

        it 'returns the created group' do
          gitlab_request

          expect(response).to have_gitlab_http_status(:success)
          expect(json_response['path']).to eq('test-group')
        end
      end

      context 'when current user cannot create group inside the organization' do
        it 'returns the error' do
          gitlab_request

          permission_error_message = "You don't have permission to create a group in the provided organization."
          error = { "organization_id" => [permission_error_message] }
          expect(json_response['message']).to eq(error)
          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end
      end
    end

    context 'when the user is not signed in' do
      it 'returns unauthorized' do
        gitlab_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
