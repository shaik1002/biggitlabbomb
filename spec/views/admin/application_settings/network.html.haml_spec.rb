# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/network.html.haml', feature_category: :groups_and_projects do
  let_it_be(:admin) { build_stubbed(:admin) }
  let_it_be(:application_setting) { build(:application_setting) }

  before do
    assign(:application_setting, application_setting)
    allow(view).to receive(:current_user) { admin }
  end

  context 'for Git HTTP rate limit' do
    it 'renders the `git_http_rate_limit_unauthenticated` field' do
      render

      expect(rendered).to have_field('application_setting_throttle_unauthenticated_git_http_enabled')
      expect(rendered).to have_field('application_setting_throttle_unauthenticated_git_http_requests_per_period')
      expect(rendered).to have_field('application_setting_throttle_unauthenticated_git_http_period_in_seconds')
    end
  end

  context 'for Projects API rate limit' do
    it 'renders the `projects_api_rate_limit_unauthenticated` field' do
      render

      expect(rendered).to have_field('application_setting_projects_api_rate_limit_unauthenticated')
    end
  end

  context 'for Members API rate limit' do
    it 'renders the `members_delete_limit` field' do
      render

      expect(rendered).to have_field('application_setting_members_delete_limit')
    end
  end
end
