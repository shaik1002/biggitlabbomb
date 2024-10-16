# frozen_string_literal: true

RSpec.shared_context 'with work_items_beta' do |flag|
  before do
    stub_feature_flags(work_items_beta: flag)
    stub_feature_flags(notifications_todos_buttons: false)

    page.refresh
    wait_for_all_requests
  end
end

RSpec.shared_examples 'work items title' do
  let(:title_selector) { '[data-testid="work-item-title-input"]' }

  it 'successfully shows and changes the title of the work item' do
    expect(work_item.reload.title).to eq work_item.title

    click_button 'Edit', match: :first
    find(title_selector).set("Work item title")
    send_keys([:command, :enter])
    wait_for_requests

    expect(work_item.reload.title).to eq 'Work item title'
  end
end

RSpec.shared_examples 'work items toggle status button' do
  it 'successfully shows and changes the status of the work item' do
    click_button 'Close', match: :first

    expect(page).to have_button 'Reopen'
    expect(work_item.reload.state).to eq('closed')
  end
end

RSpec.shared_examples 'work items comments' do |type|
  let(:is_mac) { page.evaluate_script('navigator.platform').include?('Mac') }
  let(:modifier_key) { is_mac ? :command : :control }

  def set_comment
    fill_in _('Add a reply'), with: 'Test comment'
  end

  it 'successfully creates and shows comments' do
    set_comment
    click_button "Comment"

    page.within(".main-notes-list") do
      expect(page).to have_text 'Test comment'
    end
  end

  it 'successfully updates existing comments' do
    set_comment
    click_button "Comment"
    click_button _('Edit comment')
    send_keys(" updated")
    click_button _('Save comment')

    page.within(".main-notes-list") do
      expect(page).to have_content "Test comment updated"
    end
  end

  context 'for work item note actions signed in user with developer role' do
    let_it_be(:owner) { create(:user) }

    before do
      project.add_owner(owner)
    end

    it 'shows work item note actions' do
      set_comment
      send_keys([modifier_key, :enter])

      page.within(".main-notes-list") do
        expect(page).to have_text 'Test comment'
      end

      page.within('.timeline-entry.note.note-wrapper.note-comment:last-child') do
        click_button _('More actions')

        expect(page).to have_button _('Copy link')
        expect(page).to have_button _('Assign to commenting user')
        expect(page).to have_button _('Delete comment')
        expect(page).to have_button _('Edit comment')
      end
    end
  end

  it 'successfully posts comments using shortcut and checks if textarea is blank when reinitiated' do
    set_comment
    send_keys([modifier_key, :enter])

    page.within(".main-notes-list") do
      expect(page).to have_content 'Test comment'
    end
    expect(page).to have_field _('Add a reply'), with: ''
  end

  context 'when using quick actions' do
    it 'autocompletes quick actions common to all work item types', :aggregate_failures do
      click_reply_and_enter_slash

      page.within('#at-view-commands') do
        expect(page).to have_text("/title")
        expect(page).to have_text("/shrug")
        expect(page).to have_text("/tableflip")
        expect(page).to have_text("/close")
        expect(page).to have_text("/cc")
      end
    end

    context 'when a widget is enabled' do
      before do
        WorkItems::Type.default_by_type(type).widget_definitions
          .find_by_widget_type(:assignees).update!(disabled: false)
      end

      it 'autocompletes quick action for the enabled widget' do
        click_reply_and_enter_slash

        page.within('#at-view-commands') do
          expect(page).to have_text("/assign")
        end
      end
    end

    context 'when a widget is disabled' do
      before do
        WorkItems::Type.default_by_type(type).widget_definitions
          .find_by_widget_type(:assignees).update!(disabled: true)
      end

      it 'does not autocomplete quick action for the disabled widget' do
        click_reply_and_enter_slash

        page.within('#at-view-commands') do
          expect(page).not_to have_text("/assign")
        end
      end
    end

    def click_reply_and_enter_slash
      fill_in _('Add a reply'), with: '/'
    end
  end
end

RSpec.shared_examples 'work items assignees' do
  let(:work_item_assignees_selector) { '[data-testid="work-item-assignees"]' }

  it 'successfully assigns the current user by searching',
    quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/413074' do
    # The button is only when the mouse is over the input
    find_and_click_edit(work_item_assignees_selector)

    select_listbox_item(user.username)

    find("body").click
    wait_for_all_requests

    expect(work_item.assignees).to include(user)
  end

  it 'successfully removes all users on clear all button click' do
    find_and_click_edit(work_item_assignees_selector)

    select_listbox_item(user.username)

    find("body").click
    wait_for_requests

    find_and_click_edit(work_item_assignees_selector)

    find_and_click_clear(work_item_assignees_selector)
    wait_for_all_requests

    expect(work_item.assignees).not_to include(user)
  end

  it 'updates the assignee in real-time' do
    using_session :other_session do
      visit work_items_path
      expect(work_item.reload.assignees).not_to include(user)
    end

    click_button 'assign yourself'
    wait_for_all_requests

    expect(work_item.reload.assignees).to include(user)
    using_session :other_session do
      expect(work_item.reload.assignees).to include(user)
    end
  end
end

RSpec.shared_examples 'work items labels' do
  let(:label_title_selector) { '[data-testid="labels-title"]' }
  let(:labels_input_selector) { '[data-testid="work-item-labels-input"]' }
  let(:work_item_labels_selector) { '[data-testid="work-item-labels"]' }

  it 'successfully applies the label by searching' do
    expect(work_item.reload.labels).not_to include(label)

    find_and_click_edit(work_item_labels_selector)

    select_listbox_item(label.title)

    find("body").click
    wait_for_all_requests

    expect(work_item.reload.labels).to include(label)
    within(work_item_labels_selector) do
      expect(page).to have_link(label.title)
    end
  end

  it 'successfully removes all users on clear all button click' do
    expect(work_item.reload.labels).not_to include(label)

    find_and_click_edit(work_item_labels_selector)

    select_listbox_item(label.title)

    find("body").click
    wait_for_requests

    expect(work_item.reload.labels).to include(label)

    find_and_click_edit(work_item_labels_selector)

    find_and_click_clear(work_item_labels_selector)
    wait_for_all_requests

    expect(work_item.reload.labels).not_to include(label)
  end

  it 'updates the assignee in real-time' do
    using_session :other_session do
      visit work_items_path
      expect(work_item.reload.labels).not_to include(label)
    end

    find_and_click_edit(work_item_labels_selector)

    select_listbox_item(label.title)

    find("body").click
    wait_for_all_requests

    expect(work_item.reload.labels).to include(label)

    using_session :other_session do
      expect(work_item.reload.labels).to include(label)
    end
  end
end

RSpec.shared_examples 'work items description' do
  let(:edit_button) { 'Edit' }

  it 'shows GFM autocomplete', :aggregate_failures do
    click_button edit_button, match: :first
    fill_in _('Description'), with: "@#{user.username}"

    page.within('.atwho-container') do
      expect(page).to have_text(user.name)
    end
  end

  it 'autocompletes available quick actions', :aggregate_failures do
    click_button edit_button, match: :first
    fill_in _('Description'), with: '/'

    page.within('#at-view-commands') do
      expect(page).to have_text("title")
      expect(page).to have_text("shrug")
      expect(page).to have_text("tableflip")
      expect(page).to have_text("close")
      expect(page).to have_text("cc")
    end
  end

  context 'on conflict' do
    let_it_be(:other_user) { create(:user) }
    let(:expected_warning) { 'Someone edited the description at the same time you did.' }

    before do
      project.add_developer(other_user)
      stub_feature_flags(notifications_todos_buttons: false)
    end

    it 'shows conflict message when description changes', :aggregate_failures do
      click_button edit_button, match: :first

      ::WorkItems::UpdateService.new(
        container: work_item.project,
        current_user: other_user,
        params: { description: "oh no!" }
      ).execute(work_item)

      wait_for_requests

      fill_in _('Description'), with: 'oh yeah!'

      expect(page).to have_text(expected_warning)

      page.find('summary', text: 'View current version').click
      expect(find_by_testid('conflicted-description').value).to eq('oh no!')

      click_button s_('WorkItem|Save and overwrite')

      expect(page.find('[data-testid="work-item-description"]')).to have_text("oh yeah!")
    end
  end
end

RSpec.shared_examples 'work items invite members' do
  include Features::InviteMembersModalHelpers

  let(:work_item_assignees_selector) { '[data-testid="work-item-assignees"]' }

  it 'successfully assigns the current user by searching' do
    # The button is only when the mouse is over the input
    find_and_click_edit(work_item_assignees_selector)
    wait_for_requests

    click_link('Invite members')

    page.within invite_modal_selector do
      expect(page).to have_text("You're inviting members to the #{work_item.project.name} project")
    end
  end
end

RSpec.shared_examples 'work items milestone' do
  let(:work_item_milestone_selector) { '[data-testid="work-item-milestone"]' }

  it 'has the work item milestone with edit' do
    expect(page).to have_selector(work_item_milestone_selector)
  end

  it 'passes axe automated accessibility testing in closed state' do
    expect(page).to be_axe_clean.within(work_item_milestone_selector)
  end

  it 'passes axe automated accessibility testing in open state' do
    within(work_item_milestone_selector) do
      click_button _('Edit')
      wait_for_requests

      expect(page).to be_axe_clean.within(work_item_milestone_selector)
    end
  end

  context 'when edit is clicked' do
    it 'selects and updates the right milestone', :aggregate_failures do
      find_and_click_edit(work_item_milestone_selector)

      select_listbox_item(milestones[10].title)

      wait_for_requests
      within(work_item_milestone_selector) do
        expect(page).to have_text(milestones[10].title)
      end

      find_and_click_edit(work_item_milestone_selector)

      find_and_click_clear(work_item_milestone_selector)

      expect(find(work_item_milestone_selector)).to have_content('None')
    end

    it 'searches and sets or removes milestone for the work item' do
      find_and_click_edit(work_item_milestone_selector)
      within(work_item_milestone_selector) do
        send_keys "\"#{milestones[11].title}\""
        wait_for_requests

        select_listbox_item(milestones[11].title)
        expect(page).to have_text(milestones[11].title)
      end
    end
  end
end

RSpec.shared_examples 'work items comment actions for guest users' do
  context 'for guest user' do
    it 'hides other actions other than copy link' do
      page.within(".main-notes-list") do
        click_button _('More actions'), match: :first

        expect(page).to have_button _('Copy link')
        expect(page).not_to have_button _('Assign to commenting user')
      end
    end
  end
end

RSpec.shared_examples 'work items notifications' do
  it 'displays toast when notification is toggled' do
    if Feature.enabled?(:notifications_todos_buttons)
      def notification_button
        find('button[data-testid="subscribe-button"]')
      end
      notification_button.click
      expect(page).to have_selector('svg[data-testid="notifications"]')
    else
      click_button _('More actions'), match: :first
      within_testid('notifications-toggle-form') do
        expect(page).not_to have_button(class: 'gl-toggle is-checked')

        click_button(class: 'gl-toggle')

        expect(page).to have_button(class: 'gl-toggle is-checked')
      end
    end

    expect(page).to have_css('.gl-toast', text: _('Notifications turned on.'))
  end
end

RSpec.shared_examples 'work items todos' do
  it 'adds item to the list' do
    expect(page).to have_button s_('WorkItem|Add a to do')

    click_button s_('WorkItem|Add a to do')

    expect(page).to have_button s_('WorkItem|Mark as done')

    within_testid('todos-shortcut-button') do
      expect(page).to have_content '1'
    end
  end

  it 'marks a todo as done' do
    click_button s_('WorkItem|Add a to do')
    click_button s_('WorkItem|Mark as done')

    expect(page).to have_button s_('WorkItem|Add a to do')
    within_testid('todos-shortcut-button') do
      expect(page).to have_content("")
    end
  end
end

RSpec.shared_examples 'work items award emoji' do
  let(:award_section_selector) { '.awards' }
  let(:award_button_selector) { '[data-testid="award-button"]' }
  let(:selected_award_button_selector) { '[data-testid="award-button"].selected' }
  let(:grinning_emoji_selector) { 'gl-emoji[data-name="grinning"]' }
  let(:tooltip_selector) { '.gl-tooltip' }

  def select_emoji
    page.within(award_section_selector) do
      page.first(award_button_selector).click
    end

    wait_for_requests
  end

  before do
    emoji_upvote
  end

  it 'adds award to the work item for current user' do
    select_emoji

    within(award_section_selector) do
      expect(page).to have_selector(selected_award_button_selector)

      # As the user2 has already awarded the `:thumbsup:` emoji, the emoji count will be 2
      expect(first(award_button_selector)).to have_content '2'
    end
    expect(page.find(tooltip_selector)).to have_content("John and you reacted with :thumbsup:")
  end

  it 'removes award from work item for current user' do
    select_emoji

    page.within(award_section_selector) do
      # As the user2 has already awarded the `:thumbsup:` emoji, the emoji count will be 2
      expect(first(award_button_selector)).to have_content '2'
    end

    select_emoji

    page.within(award_section_selector) do
      # The emoji count will be back to 1
      expect(first(award_button_selector)).to have_content '1'
    end
  end

  it 'add custom award to the work item for current user' do
    within(award_section_selector) do
      click_button _('Add reaction')
      find(grinning_emoji_selector).click

      expect(page).to have_selector(grinning_emoji_selector)
    end
  end
end

RSpec.shared_examples 'work items parent' do |type|
  let(:work_item_parent) { create(:work_item, type, project: project) }

  def set_parent(parent_text)
    find('[data-testid="listbox-search-input"] .gl-listbox-search-input',
      visible: true).send_keys "\"#{parent_text}\""
    wait_for_requests

    find('.gl-new-dropdown-item', text: parent_text).click
    wait_for_all_requests
  end

  it 'searches and sets or removes parent for the work item' do
    find_by_testid('edit-parent').click
    within_testid('work-item-parent-form') do
      set_parent(work_item_parent.title)
    end

    expect(find_by_testid('work-item-parent-link')).to have_text(work_item_parent.title)
    wait_for_requests

    page.refresh
    find_by_testid('edit-parent').click

    click_button('Unassign')
    wait_for_requests

    expect(find_by_testid('work-item-parent-none')).to have_text('None')
  end
end

def find_and_click_edit(selector)
  within(selector) do
    click_button 'Edit'
  end
end

def find_and_click_clear(selector)
  within(selector) do
    click_button 'Clear'
  end
end

RSpec.shared_examples 'work items iteration' do
  let(:work_item_iteration_selector) { '[data-testid="work-item-iteration"]' }
  let_it_be(:iteration_cadence) { create(:iterations_cadence, group: group, active: true) }
  let_it_be(:iteration) do
    create(
      :iteration,
      iterations_cadence: iteration_cadence,
      group: group,
      start_date: 1.day.from_now,
      due_date: 2.days.from_now
    )
  end

  let_it_be(:iteration2) do
    create(
      :iteration,
      iterations_cadence: iteration_cadence,
      group: group,
      start_date: 2.days.ago,
      due_date: 1.day.ago,
      state: 'closed',
      skip_future_date_validation: true
    )
  end

  it 'has the work item iteration with edit' do
    expect(page).to have_selector(work_item_iteration_selector)
  end

  it 'passes axe automated accessibility testing in closed state' do
    expect(page).to be_axe_clean.within(work_item_iteration_selector)
  end

  it 'passes axe automated accessibility testing in open state' do
    within(work_item_iteration_selector) do
      click_button _('Edit')
      wait_for_requests

      expect(page).to be_axe_clean.within(work_item_iteration_selector)
    end
  end

  context 'when edit is clicked' do
    it 'selects and updates the right iteration', :aggregate_failures do
      find_and_click_edit(work_item_iteration_selector)

      within(work_item_iteration_selector) do
        expect(page).to have_text(iteration_cadence.title)
        expect(page).to have_text(iteration.period)
      end

      select_listbox_item(iteration.period)

      wait_for_requests

      within(work_item_iteration_selector) do
        expect(page).to have_text(iteration_cadence.title)
        expect(page).to have_text(iteration.period)
      end

      find_and_click_edit(work_item_iteration_selector)

      find_and_click_clear(work_item_iteration_selector)

      expect(find(work_item_iteration_selector)).to have_content('None')
    end

    it 'searches and sets or removes iteration for the work item' do
      find_and_click_edit(work_item_iteration_selector)
      within(work_item_iteration_selector) do
        send_keys(iteration.title)
        wait_for_requests

        select_listbox_item(iteration.period)
        expect(page).to have_text(iteration.period)
      end
    end
  end
end

RSpec.shared_context 'with work_items_rolledup_dates' do |flag|
  before do
    stub_feature_flags(work_items_rolledup_dates: flag)

    page.refresh
    wait_for_all_requests
  end
end

RSpec.shared_examples 'work items rolled up dates' do
  let(:work_item_rolledup_dates_selector) { '[data-testid="work-item-rolledup-dates"]' }

  include_context 'with work_items_rolledup_dates', true

  it 'passes axe automated accessibility testing in closed state' do
    expect(page).to have_selector(work_item_rolledup_dates_selector)
    expect(page).to be_axe_clean.within(work_item_rolledup_dates_selector)
  end

  it 'passes axe automated accessibility testing in open state' do
    within(work_item_rolledup_dates_selector) do
      click_button _('Edit')
      wait_for_requests

      expect(page).to be_axe_clean.within(work_item_rolledup_dates_selector)
    end
  end

  context 'when edit is clicked' do
    it 'selects and updates the dates to fixed once selected', :aggregate_failures do
      expect(find_field('Inherited')).to be_checked

      find_and_click_edit(work_item_rolledup_dates_selector)

      within work_item_rolledup_dates_selector do
        fill_in 'Start', with: '2021-01-01'
        fill_in 'Due', with: '2021-01-02'
      end

      # Click outside to save
      find("body").click

      within work_item_rolledup_dates_selector do
        expect(find_field('Fixed')).to be_checked
        expect(page).to have_text('Start: Jan 1, 2021')
        expect(page).to have_text('Due: Jan 2, 2021')
      end
    end
  end

  context 'when feature flag is disabled' do
    include_context 'with work_items_rolledup_dates', false

    it 'does not show rolled up dates' do
      expect(page).not_to have_selector(work_item_rolledup_dates_selector)
    end
  end
end

RSpec.shared_examples 'work items time tracking' do
  it 'passes axe automated accessibility testing for estimate and time spent modals', :aggregate_failures do
    click_button 'estimate'

    expect(page).to be_axe_clean.within('[role="dialog"]')

    click_button 'Close'
    click_button 'time spent'

    expect(page).to be_axe_clean.within('[role="dialog"]')
  end

  it 'adds and removes an estimate', :aggregate_failures do
    click_button 'estimate'
    fill_in 'Estimate', with: '5d'
    click_button 'Save'

    expect(page).to have_text 'Estimate 5d'
    expect(page).to have_button '5d'
    expect(page).not_to have_button 'estimate'

    click_button '5d'
    click_button 'Remove'

    expect(page).not_to have_text 'Estimate 5d'
    expect(page).not_to have_button '5d'
    expect(page).to have_button 'estimate'
  end

  it 'adds and deletes time entries and view report', :aggregate_failures do
    click_button 'time entry'
    fill_in 'Time spent', with: '1d'
    fill_in 'Summary', with: 'First summary'
    click_button 'Save'

    click_button 'Add time entry'
    fill_in 'Time spent', with: '2d'
    fill_in 'Summary', with: 'Second summary'
    click_button 'Save'

    expect(page).to have_text 'Spent 3d'
    expect(page).to have_button '3d'

    click_button '3d'

    expect(page).to have_css 'h2', text: 'Time tracking report'
    expect(page).to have_text "1d #{user.name} First summary"
    expect(page).to have_text "2d #{user.name} Second summary"

    click_button 'Delete time spent', match: :first

    expect(page).to have_text "1d #{user.name} First summary"
    expect(page).not_to have_text "2d #{user.name} Second summary"

    click_button 'Close'

    expect(page).to have_text 'Spent 1d'
    expect(page).to have_button '1d'
  end
end
