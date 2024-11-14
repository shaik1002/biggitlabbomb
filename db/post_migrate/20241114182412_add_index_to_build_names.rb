# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexToBuildNames < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.7'
  disable_ddl_transaction!

  TABLE_NAME = :p_ci_build_names
  INDEX_NAME = :index_p_ci_build_names_on_search_columns
  COLUMNS = %i[project_id name build_id partition_id]

  def up
    add_concurrent_partitioned_index(TABLE_NAME, COLUMNS, name: INDEX_NAME)
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
