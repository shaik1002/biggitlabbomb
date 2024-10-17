# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueCreateComplianceStandardsAdherence, feature_category: :compliance_management do
  let!(:batched_migration) { described_class::MIGRATION }

  context 'for EE' do
    before do
      allow(Gitlab).to receive(:ee?).and_return(true)
    end

    it 'schedules a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).to have_scheduled_batched_migration(
            table_name: :projects,
            column_name: :id,
            interval: described_class::DELAY_INTERVAL,
            batch_size: described_class::BATCH_SIZE,
            sub_batch_size: described_class::SUB_BATCH_SIZE
          )
        }
      end
    end
  end

  context 'for FOSS' do
    before do
      allow(Gitlab).to receive(:ee?).and_return(false)
    end

    it 'does not schedules a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }
      end
    end
  end
end
