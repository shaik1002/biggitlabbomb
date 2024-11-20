# frozen_string_literal: true

class BackfillGroupIdForWikiPageEvents < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.6'

  BATCH_SIZE = 500

  def up
    builds_model = define_batchable_model('events')

    builds_model.where(target_type: 'WikiPage::Meta', project_id: nil, group_id: nil).each_batch(column: :id) do |batch|
      batch
        .where('events.target_id = wiki_page_meta.id')
        .update_all('group_id = wiki_page_meta.namespace_id FROM wiki_page_meta')
    end
  end

  def down
    # no-op
  end
end
