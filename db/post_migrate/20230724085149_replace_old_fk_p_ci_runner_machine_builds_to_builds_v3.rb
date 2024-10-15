# frozen_string_literal: true

class ReplaceOldFkPCiRunnerMachineBuildsToBuildsV3 < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  def up
    return if new_foreign_key_exists?

    with_lock_retries do
      remove_foreign_key_if_exists :p_ci_runner_machine_builds, :ci_builds,
        name: :fk_bb490f12fe_p, reverse_lock_order: true

      rename_constraint :p_ci_runner_machine_builds, :temp_fk_bb490f12fe_p, :fk_bb490f12fe_p

      Gitlab::Database::PostgresPartitionedTable.each_partition(:p_ci_runner_machine_builds) do |partition|
        rename_constraint partition.identifier, :temp_fk_bb490f12fe_p, :fk_bb490f12fe_p
      end
    end
  end

  def down
    return unless new_foreign_key_exists?

    add_concurrent_partitioned_foreign_key :p_ci_runner_machine_builds, :ci_builds,
      name: :temp_fk_bb490f12fe_p,
      column: [:partition_id, :build_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      validate: true,
      reverse_lock_order: true

    switch_constraint_names :p_ci_runner_machine_builds, :fk_bb490f12fe_p, :temp_fk_bb490f12fe_p

    Gitlab::Database::PostgresPartitionedTable.each_partition(:p_ci_runner_machine_builds) do |partition|
      switch_constraint_names partition.identifier, :fk_bb490f12fe_p, :temp_fk_bb490f12fe_p
    end
  end

  private

  def new_foreign_key_exists?
    foreign_key_exists?(:p_ci_runner_machine_builds, :p_ci_builds, name: :fk_bb490f12fe_p)
  end
end
