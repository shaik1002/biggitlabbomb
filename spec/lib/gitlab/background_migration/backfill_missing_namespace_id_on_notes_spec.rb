# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMissingNamespaceIdOnNotes, feature_category: :code_review_workflow do
  let(:namespaces_table) { table(:namespaces) }
  let(:notes_table) { table(:notes) }
  let(:projects_table) { table(:projects) }
  let(:snippets_table) { table(:snippets) }
  let(:users_table) { table(:users) }

  let(:namespace_1) { namespaces_table.create!(name: 'namespace', path: 'namespace-path-1') }
  let(:project_namespace_2) { namespaces_table.create!(name: 'namespace', path: 'namespace-path-2', type: 'Project') }

  let!(:project_1) do
    projects_table
    .create!(
      name: 'project1',
      path: 'path1',
      namespace_id: namespace_1.id,
      project_namespace_id: project_namespace_2.id,
      visibility_level: 0
    )
  end

  let!(:user_1) { users_table.create!(name: 'bob', email: 'bob@example.com', projects_limit: 1) }

  context "when namespace_id is derived from note.project_id" do
    let(:alert_management_alert_note) do
      notes_table.create!(project_id: project_1.id, noteable_type: "AlertManagement::Alert")
    end

    let(:commit_note) { notes_table.create!(project_id: project_1.id, noteable_type: "Commit") }
    let(:merge_request_note) { notes_table.create!(project_id: project_1.id, noteable_type: "MergeRequest") }
    let(:vulnerability_note) { notes_table.create!(project_id: project_1.id, noteable_type: "Vulnerability") }
    let(:design_note) { notes_table.create!(project_id: project_1.id, noteable_type: "Design") }
    let(:work_item_note) { notes_table.create!(project_id: project_1.id, noteable_type: "WorkItem") }
    let(:issue_note) { notes_table.create!(project_id: project_1.id, noteable_type: "Issue") }
    let(:epic_note) { notes_table.create!(project_id: project_1.id, noteable_type: "Epic") }

    it "updates the namespace_id" do
      [
        alert_management_alert_note,
        commit_note,
        merge_request_note,
        vulnerability_note,
        design_note,
        work_item_note,
        issue_note,
        epic_note
      ].each do |test_note|
        expect(test_note.project_id).not_to be_nil

        test_note.update_columns(namespace_id: nil)
        test_note.reload

        expect(test_note.namespace_id).to be_nil

        described_class.new(
          start_id: test_note.id,
          end_id: test_note.id,
          batch_table: :notes,
          batch_column: :id,
          sub_batch_size: 1,
          pause_ms: 0,
          connection: ActiveRecord::Base.connection
        ).perform

        test_note.reload

        expect(test_note.namespace_id).not_to be_nil
        expect(test_note.namespace_id).to eq(Project.find(test_note.project_id).namespace_id)
      end
    end
  end

  context "when namespace_id is derived from noteable.author.namespace_id" do
    let!(:snippet) do
      snippets_table.create!(
        author_id: user_1.id,
        project_id: project_1.id
      )
    end

    let(:personal_snippet_note) do
      notes_table.create!(author_id: user_1.id, noteable_type: "Snippet", noteable_id: snippet.id)
    end

    let(:project_snippet_note) do
      notes_table.create!(author_id: user_1.id, noteable_type: "Snippet", noteable_id: snippet.id)
    end

    let!(:user_namespace) do
      namespaces_table.create!(name: 'namespace', path: 'user-namespace-path', type: 'User', owner_id: user_1.id)
    end

    it "updates the namespace_id" do
      [project_snippet_note, personal_snippet_note].each do |test_note|
        test_note.update_columns(namespace_id: nil)
        test_note.reload

        expect(test_note.namespace_id).to be_nil

        described_class.new(
          start_id: test_note.id,
          end_id: test_note.id,
          batch_table: :notes,
          batch_column: :id,
          sub_batch_size: 1,
          pause_ms: 0,
          connection: ActiveRecord::Base.connection
        ).perform

        test_note.reload

        expect(test_note.namespace_id).not_to be_nil
        expect(test_note.namespace_id).to eq(user_namespace.id)
      end
    end
  end

  context "when noteable_type is nil" do
    let(:merge_request_note) { notes_table.create!(project_id: project_1.id, noteable_type: "MergeRequest") }

    it "deletes the note" do
      expect_next_instance_of(described_class) do |migration|
        expect(migration).to receive(:backfillable?).and_return(false)
      end

      test_note = merge_request_note

      migration = described_class.new(
        start_id: test_note.id,
        end_id: test_note.id,
        batch_table: :notes,
        batch_column: :id,
        sub_batch_size: 1,
        pause_ms: 0,
        connection: ActiveRecord::Base.connection
      )

      expect { migration.perform }.to change { Note.count }.by(-1)
    end
  end
end
