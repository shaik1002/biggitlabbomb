# frozen_string_literal: true

class CreateCiInstanceRunnerMonthlyUsages < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def up
    # rubocop:disable Migration/EnsureFactoryForTable -- False Positive
    create_table :ci_instance_runner_monthly_usages do |t|
      t.bigint :runner_id, null: false
      t.date :date, null: false
      t.bigint :runner_duration, null: false, default: 0
      t.decimal :amount_used, precision: 18, scale: 4, null: false, default: 0.0
      t.bigint :project_id
      t.bigint :namespace_id

      t.timestamps_with_timezone null: false
    end

    add_index :ci_instance_runner_monthly_usages, [:namespace_id, :date],
      name: 'index_ci_instance_runner_monthly_usages_on_namespace_and_month'

    add_index :ci_instance_runner_monthly_usages, [:runner_id, :date],
      name: 'index_ci_instance_runner_monthly_usages_on_runner_and_month'

    add_index :ci_instance_runner_monthly_usages, [:project_id, :date],
      name: 'index_ci_instance_runner_monthly_usages_on_project_and_month'

    execute <<-SQL
      ALTER TABLE ci_instance_runner_monthly_usages
      ADD CONSTRAINT ci_instance_runner_monthly_usages_year_month_constraint
      CHECK (date = date_trunc('month', date::timestamp with time zone))
    SQL
    # rubocop:enable Migration/EnsureFactoryForTable -- False Positive
  end

  def down
    drop_table :ci_instance_runner_monthly_usages
  end
end
