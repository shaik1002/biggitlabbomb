# frozen_string_literal: true

class AddLfkTriggersToNotes < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '17.6'

  def up
    track_record_deletions(:vulnerabilities)
  end

  def down
    untrack_record_deletions(:vulnerabilities)
  end
end
