# frozen_string_literal: true

class PrepareAsyncIndexOnSbomOccurrencesForAggregations < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_sbom_occurrences_for_aggregations'

  milestone '16.11'

  def up
    prepare_async_index :sbom_occurrences, [:traversal_ids, :component_id, :component_version_id], name: INDEX_NAME
  end

  def down
    unprepare_async_index :sbom_occurrences, INDEX_NAME
  end
end
