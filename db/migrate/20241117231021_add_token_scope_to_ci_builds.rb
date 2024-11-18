# frozen_string_literal: true

class AddTokenScopeToCiBuilds < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :p_ci_builds, :token_scope, :text, if_not_exists: true # rubocop:disable Migration/AddColumnsToWideTables -- this is a spike
    end

    add_text_limit :p_ci_builds, :token_scope, 255
  end

  def down
    with_lock_retries do
      remove_column :p_ci_builds, :token_scope, :text, if_not_exists: true
    end
  end
end
