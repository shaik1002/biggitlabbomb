# frozen_string_literal: true

class CreateSecurityPipelineExecutionSchedules < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    create_table :security_pipeline_execution_schedules do |t|
      t.timestamps_with_timezone null: false
      t.references :security_policy, foreign_key: { on_delete: :cascade }, null: false, index: false
      t.references :project, foreign_key: { on_delete: :cascade }, null: false, index: false
      t.text :cron, null: false, limit: 255
      t.datetime_with_timezone :next_run_at, null: false
    end

    #TODO: add indexes
  end
end
