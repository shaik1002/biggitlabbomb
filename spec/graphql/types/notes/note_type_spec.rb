# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Note'], feature_category: :team_planning do
  include GraphqlHelpers

  it 'exposes the expected fields' do
    expected_fields = %i[
      author
      body
      body_html
      body_first_line_html
      award_emoji
      imported
      internal
      created_at
      discussion
      id
      position
      project
      resolvable
      resolved
      resolved_at
      resolved_by
      system
      system_note_icon_name
      updated_at
      user_permissions
      url
      last_edited_at
      last_edited_by
      system_note_metadata
      max_access_level_of_author
      author_is_contributor
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Note) }
  specify { expect(described_class).to require_graphql_authorizations(:read_note) }

  context 'when system note with issue_email_participants action', feature_category: :service_desk do
    let_it_be(:user) { build_stubbed(:user) }
    let_it_be(:email) { 'user@example.com' }
    let_it_be(:note_text) { "added #{email}" }
    # Create project and issue separately because we need to public project.
    # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Notes::RenderService updates #note and #cached_markdown_version
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:note) do
      create(:note, :system, project: project, noteable: issue, author: Users::Internal.support_bot, note: note_text)
    end

    let_it_be(:system_note_metadata) { create(:system_note_metadata, note: note, action: :issue_email_participants) }
    # rubocop:enable RSpec/FactoryBot/AvoidCreate

    let(:obfuscated_email) { 'us*****@e*****.c**' }

    describe '#body' do
      subject { resolve_field(:body, note, current_user: user) }

      it_behaves_like 'a note content field with obfuscated email address'
    end

    describe '#body_html' do
      subject { resolve_field(:body_html, note, current_user: user) }

      it_behaves_like 'a note content field with obfuscated email address'
    end
  end

  describe '#body_first_line_html' do
    let_it_be(:user) { build_stubbed(:user) }
    let_it_be(:project) { build(:project, :public) }

    let(:note_text) { 'note body content' }
    let(:note) { build(:note, note: note_text, project: project) }

    subject(:resolve_result) { resolve_field(:body_first_line_html, note, current_user: user) }

    it 'calls first_line_in_markdown with the expected arguments' do
      expect_next_instance_of(described_class) do |note_type|
        expect(note_type).to receive(:first_line_in_markdown)
          .with(kind_of(NotePresenter), :note, 125, project: note.project)
          .and_call_original
      end

      resolve_result
    end

    context 'when the note body is shorter than 125 characters' do
      it 'returns the content unchanged' do
        expect(resolve_result).to eq('<p>note body content</p>')
      end
    end

    context 'when the note body is longer than 125 characters' do
      let(:note_text) do
        'this is a note body content which is very, very, very, veeery, long and is supposed ' \
          'to be longer that 125 characters in length, with a few extra'
      end

      it 'returns the content trimmed with an ellipsis' do
        expect(resolve_result).to eq(
          '<p>this is a note body content which is very, very, very, veeery, long and is supposed ' \
            'to be longer that 125 characters in le...</p>')
      end
    end
  end
end
