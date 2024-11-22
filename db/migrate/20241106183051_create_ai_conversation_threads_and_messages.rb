# frozen_string_literal: true

class CreateAiConversationThreadsAndMessages < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    create_table :ai_conversation_threads, primary_key: [:id, :last_updated_at], # rubocop:disable Migration/EnsureFactoryForTable -- https://gitlab.com/gitlab-org/gitlab/-/issues/468630
      options: 'PARTITION BY RANGE (last_updated_at)' do |t|
      t.bigserial :id, null: false
      t.bigint :user_id, null: false
      t.bigint :organization_id, null: false
      t.datetime_with_timezone :last_updated_at, null: false, default: -> { 'NOW()' }
      t.timestamps_with_timezone null: false
      t.integer :conversation_type, limit: 2, null: false

      t.index :last_updated_at
      t.index :organization_id
      t.index :user_id
    end

    create_table :ai_conversation_messages, primary_key: [:id, :created_at], # rubocop:disable Migration/EnsureFactoryForTable -- https://gitlab.com/gitlab-org/gitlab/-/issues/468630
      options: 'PARTITION BY RANGE (created_at)' do |t|
      t.bigserial :id, null: false
      t.bigint :thread_id, null: false
      t.bigint :agent_version_id, null: true
      t.bigint :organization_id, null: false
      t.datetime_with_timezone :thread_last_updated_at, null: false
      t.timestamps_with_timezone null: false
      t.integer :role, limit: 2, null: false
      t.boolean :has_feedback, default: false
      t.jsonb :extras, default: {}, null: false
      t.jsonb :error_details, default: {}, null: false
      t.text :content, null: false, limit: 512.kilobytes
      t.text :request_xid, limit: 255
      t.text :message_xid, limit: 255
      t.text :referer_url, limit: 255
      t.text :timestamp, limit: 255 # rubocop:disable Migration/Datetime -- Timestamp is the field name, not the data type

      t.index [:thread_id, :thread_last_updated_at, :created_at], unique: true,
        name: 'idx_ai_convo_msgs_on_thread_id_last_updated_at_and_created_at'
      t.index [:thread_id, :created_at]
      t.index :message_xid
      t.index :organization_id
      t.index :agent_version_id
    end
  end
end
