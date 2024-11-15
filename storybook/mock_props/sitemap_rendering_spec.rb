# spec/features/sitemap_rendering_spec.rb

require 'spec_helper'
require 'support/helpers/rails_helpers'
require 'capybara/rspec'

RSpec.describe 'Sitemap URL Rendering', type: :feature, feature_category: :navigation do
  # Helper method to generate the sitemap
  def generate_sitemap(_group, project)
    group_urls = [
      "http://127.0.0.1:3000/\#{group.full_path}",
      "http://127.0.0.1:3000/groups/\#{group.full_path}/-/issues",
      "http://127.0.0.1:3000/groups/\#{group.full_path}/-/merge_requests",
      "http://127.0.0.1:3000/groups/\#{group.full_path}/-/packages",
      "http://127.0.0.1:3000/groups/\#{group.full_path}/-/epics"
    ]

    project_urls = [
      "http://127.0.0.1:3000/\#{project.full_path}",

      ("http://127.0.0.1:3000/\#{project.full_path}/-/merge_requests" if project.feature_available?(:merge_requests,
        user)),

      ("http://127.0.0.1:3000/\#{project.full_path}/-/issues" if project.feature_available?(:issues, user)),
      ("http://127.0.0.1:3000/\#{project.full_path}/-/snippets" if project.feature_available?(:snippets, user)),
      ("http://127.0.0.1:3000/\#{project.full_path}/-/wikis/home" if project.feature_available?(:wiki, user))
    ].compact

    (group_urls + project_urls).uniq
  end

  let(:group) { Group.first || create(:group, name: 'example-group') }
  let(:project) { Project.first || create(:project, name: 'example-project', namespace: group) }
  let(:user) { User.first || create(:user, :admin) }

  before do
    login_as(user, scope: :user)
  end

  it 'generates a sitemap and ensures all URLs render correctly' do
    Capybara.default_driver = :selenium_chrome_no_headless

    Capybara.default_max_wait_time = 10

    generate_sitemap(group, project).each do |url|
      puts "Generated Sitemap URL: \#{url}"

      visit url

      expect(page).to have_content(''), "Failed to load URL: \#{url}"
      expect(page).to have_selector('header')
      expect(page).to have_selector('footer')
    end
  end
end
