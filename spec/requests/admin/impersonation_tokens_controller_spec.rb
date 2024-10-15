# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ImpersonationTokensController, :enable_admin_mode, feature_category: :system_access do
  let(:admin) { create(:admin) }
  let!(:user) { create(:user) }

  before do
    sign_in(admin)
  end

  context 'when impersonation is enabled' do
    before do
      stub_config_setting(impersonation_enabled: true)
    end

    it 'responds ok' do
      get admin_user_impersonation_tokens_path(user_id: user.username)

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  context "when impersonation is disabled" do
    before do
      stub_config_setting(impersonation_enabled: false)
    end

    it "shows error page for index page" do
      get admin_user_impersonation_tokens_path(user_id: user.username)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "responds with 404 for create action" do
      post admin_user_impersonation_tokens_path(user_id: user.username)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "responds with 404 for revoke action" do
      token = create(:personal_access_token, :impersonation, user: user)

      put revoke_admin_user_impersonation_token_path(user_id: user.username, id: token.id)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe "#create" do
    it_behaves_like "#create access token" do
      let(:url) { admin_user_impersonation_tokens_path(user_id: user.username) }
    end
  end
end
