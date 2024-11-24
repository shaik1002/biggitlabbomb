# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'doorkeeper access', feature_category: :system_access do
  let_it_be(:organization) { create(:organization) }
  let!(:user) { create(:user) }
  let!(:application) { Doorkeeper::Application.create!(name: "MyApp", redirect_uri: "https://app.com", owner: user) }
  let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id, scopes: "api", organization_id: organization.id }

  describe 'access token with composite identity', :request_store do
    let!(:user) { create(:user, name: 'gitlab-duo') }

    context 'when user one is scoped to user two' do
      let(:scope_user) { create(:user) }
      let(:project) { create(:project, :private) }

      before do
        allow_any_instance_of(token.class).to receive(:scope_user).and_return(scope_user) # rubocop:disable RSpec/AnyInstanceOf -- TODO

        project.add_developer(user) # shadow user doesn't have access
      end

      it 'restricts user access permissions' do
        get api("/projects/#{project.id}"), params: { access_token: token.plaintext_token }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when both users have access to a resource' do
        before do
          project.add_developer(scope_user)
        end

        it 'allows access' do
          get api("/projects/#{project.id}"), params: { access_token: token.plaintext_token }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe "unauthenticated" do
    it "returns authentication success" do
      get api("/user"), params: { access_token: token.plaintext_token }
      expect(response).to have_gitlab_http_status(:ok)
    end

    include_examples 'user login request with unique ip limit' do
      def gitlab_request
        get api('/user'), params: { access_token: token.plaintext_token }
      end
    end
  end

  describe "when token invalid" do
    it "returns authentication error" do
      get api("/user"), params: { access_token: "123a" }
      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  describe "authorization by OAuth token" do
    it "returns authentication success" do
      get api("/user", user)
      expect(response).to have_gitlab_http_status(:ok)
    end

    include_examples 'user login request with unique ip limit' do
      def gitlab_request
        get api('/user', user)
      end
    end
  end

  shared_examples 'forbidden request' do
    it 'returns 403 response' do
      get api("/user"), params: { access_token: token.plaintext_token }

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  context "when user is blocked" do
    before do
      user.block
    end

    it_behaves_like 'forbidden request'
  end

  context "when user is ldap_blocked" do
    before do
      user.ldap_block
    end

    it_behaves_like 'forbidden request'
  end

  context "when user is deactivated" do
    before do
      user.deactivate
    end

    it_behaves_like 'forbidden request'
  end

  context 'when user is blocked pending approval' do
    before do
      user.block_pending_approval
    end

    it_behaves_like 'forbidden request'
  end
end
