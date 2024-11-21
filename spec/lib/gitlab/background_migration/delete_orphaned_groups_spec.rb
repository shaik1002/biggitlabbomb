# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteOrphanedGroups, feature_category: :groups_and_projects do
  let(:namespaces) { table(:namespaces) }
  let!(:parent) { namespaces.create!(name: 'Group', type: 'Group', path: 'space1') }

  subject(:background_migration) do
    described_class.new(
      start_id: namespaces.without(parent).minimum(:id),
      end_id: namespaces.maximum(:id),
      batch_table: :namespaces,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    ).perform
  end

  describe '#perform' do
    before do
      # Remove constraint to allow creation of invalid records
      ApplicationRecord.connection.execute("ALTER TABLE namespaces DROP CONSTRAINT fk_7f813d8c90;")
    end

    after do
      # Re-create constraint after the test
      ApplicationRecord.connection.execute(<<~SQL)
        ALTER TABLE ONLY namespaces ADD CONSTRAINT fk_7f813d8c90
        FOREIGN KEY (parent_id) REFERENCES namespaces(id) ON DELETE RESTRICT NOT VALID;
      SQL
    end

    it 'processes orphaned groups and projects correctly' do
      orphaned_groups = (1..4).map do |i|
        namespaces.create!(name: "Group #{i}", path: "group_#{i}", type: 'Group', parent_id: parent.id)
      end

      orphaned_projects = (1..4).map do |i|
        namespaces.create!(name: "Project #{i}", path: "project_#{i}", type: 'Project', parent_id: parent.id)
      end

      parent.destroy!

      orphaned_groups.each do |group|
        expect(::GroupDestroyWorker).to receive(:perform).with(group.id, ::Users::Internal.admin_bot.id)
      end

      orphaned_projects.each do |project|
        expect(::Namespaces::ProjectNamespace).to receive(:delete).with(project.id)
      end

      background_migration
    end
  end
end
