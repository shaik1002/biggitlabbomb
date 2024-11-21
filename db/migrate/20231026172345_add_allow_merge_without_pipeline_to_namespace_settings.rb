# frozen_string_literal: true

class AddAllowMergeWithoutPipelineToNamespaceSettings < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '16.6'

  def change
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :namespace_settings, :allow_merge_without_pipeline, :boolean, default: false, null: false
    # rubocop:enable Migration/PreventAddingColumns
  end
end
