# frozen_string_literal: true

class DropWorkspacesDesiredConfigGeneratorVersionDefault < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def up
    connection.execute(<<~SQL)
      ALTER TABLE workspaces ALTER COLUMN desired_config_generator_version DROP DEFAULT;
    SQL
  end

  def down
    connection.execute(<<~SQL)
      ALTER TABLE workspaces ALTER COLUMN desired_config_generator_version SET DEFAULT 1;
    SQL
  end
end
