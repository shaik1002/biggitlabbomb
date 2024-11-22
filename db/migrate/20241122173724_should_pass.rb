# frozen_string_literal: true

class ShouldPass < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def up
    execute(<<~SQL)
      SELECT 1
    SQL
  end

  def down
    execute(<<~SQL)
      SELECT 1
    SQL
  end
end
