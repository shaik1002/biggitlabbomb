# frozen_string_literal: true

class ConsolidateCommonMetrics < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  require Rails.root.join('db/importers/common_metrics_importer.rb')

  DOWNTIME = false

  def up
    Importers::CommonMetricsImporter.new.execute
  end

  def down
    # no-op
  end
end
