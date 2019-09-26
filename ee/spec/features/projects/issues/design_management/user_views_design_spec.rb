require 'spec_helper'

describe 'User views issue designs', :js do
  include DesignManagementTestHelpers

  set(:project) { create(:project_empty_repo, :public) }
  set(:issue) { create(:issue, project: project) }
  set(:design) { create(:design, :with_file, issue: issue) }

  before do
    enable_design_management

    visit project_issue_path(project, issue)

    click_link 'Designs'

    wait_for_requests
  end

  it 'opens design detail' do
    find('.js-design-list-item', match: :first).click

    page.within(find('.js-design-header')) do
      expect(page).to have_content(design.filename)
    end

    expect(page).to have_selector('.js-design-image')
  end
end
