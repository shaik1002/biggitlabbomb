# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FanOutMigratePermanentlyDisabledWebhookIntoTemporarilyDisabled, :freeze_time, feature_category: :integrations do
  let!(:web_hooks) { table(:web_hooks) }

  let!(:non_disabled_webhook) { web_hooks.create!(recent_failures: 3, backoff_count: 3) }
  let!(:permanently_disabled_webhook) { web_hooks.create!(recent_failures: 4, backoff_count: 5) }

  let!(:temporarily_disabled_webhook) do
    web_hooks.create!(recent_failures: 4, backoff_count: 5, disabled_until: Time.current + 1.minute)
  end

  let!(:migration_attrs) do
    {
      start_id: web_hooks.minimum(:id),
      end_id: web_hooks.maximum(:id),
      batch_table: :web_hooks,
      batch_column: :id,
      sub_batch_size: web_hooks.count,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  it 'migrates permanently disabled web hooks to temporarily disabled' do
    described_class.new(**migration_attrs).perform

    [non_disabled_webhook, temporarily_disabled_webhook, permanently_disabled_webhook].each(&:reload)

    expect(non_disabled_webhook.recent_failures).to eq(3)
    expect(non_disabled_webhook.backoff_count).to eq(3)
    expect(non_disabled_webhook.disabled_until).to be_nil

    expect(temporarily_disabled_webhook.recent_failures).to eq(4)
    expect(temporarily_disabled_webhook.backoff_count).to eq(5)
    expect(temporarily_disabled_webhook.disabled_until).to eq(Time.current + 1.minute)

    expect(permanently_disabled_webhook.recent_failures).to eq(4)
    expect(permanently_disabled_webhook.backoff_count).to eq(100)
    expect(permanently_disabled_webhook.disabled_until).to be_within(10.minutes).of(Time.current)

    expect(web_hooks.where(disabled_until: nil).where('recent_failures > 3').count).to eq(0)
  end
end
