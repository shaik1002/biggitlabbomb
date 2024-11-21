# frozen_string_literal: true

class AddCascadeMathRenderingLimits < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  enable_lock_retries!

  def change
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :namespace_settings, :math_rendering_limits_enabled, :boolean, null: true
    # rubocop:enable Migration/PreventAddingColumns
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :namespace_settings, :lock_math_rendering_limits_enabled, :boolean, default: false, null: false
    # rubocop:enable Migration/PreventAddingColumns
    add_column :application_settings, :lock_math_rendering_limits_enabled, :boolean, default: false, null: false
  end
end
