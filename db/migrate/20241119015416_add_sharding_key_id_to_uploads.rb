# frozen_string_literal: true

class AddShardingKeyIdToUploads < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def up
    add_column :uploads, :sharding_key_id, :bigint
  end

  def down
    remove_column :uploads, :sharding_key_id
  end
end
