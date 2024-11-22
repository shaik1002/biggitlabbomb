# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueFixProjectSettingsHasVulnerabilities, feature_category: :vulnerability_management do
  let!(:batched_migration) { described_class::MIGRATION }

  before(:all) do
    # Some spec in this file currently fails when a sec database is configured. We plan to ensure it all functions
    # and passes prior to the sec db rollout.
    # Consult https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170283 for more info.
    skip_if_multiple_databases_are_setup(:sec)
  end

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          gitlab_schema: :gitlab_sec,
          table_name: :vulnerability_reads,
          column_name: :project_id,
          batch_class_name: 'LooseIndexScanBatchingStrategy',
          interval: described_class::DELAY_INTERVAL,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE
        )
      }
    end
  end
end
