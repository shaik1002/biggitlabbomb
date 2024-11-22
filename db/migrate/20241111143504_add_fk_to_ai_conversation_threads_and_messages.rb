# frozen_string_literal: true

class AddFkToAiConversationThreadsAndMessages < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.7'
  disable_ddl_transaction!

  THREADS_TO_USERS_FK = :fk_ai_threads_to_users
  THREADS_TO_ORGANIZATIONS_FK = :fk_ai_threads_to_organizations
  MESSAGES_TO_THREADS_FK = :fk_ai_messages_to_threads
  MESSAGES_TO_AGENT_VERSIONS_FK = :fk_ai_messages_to_agent_versions
  MESSAGES_TO_ORGANIZATIONS_FK = :fk_ai_messages_to_organizations

  def up
    add_concurrent_partitioned_foreign_key(
      :ai_conversation_threads, :users,
      column: :user_id,
      on_delete: :cascade,
      name: THREADS_TO_USERS_FK)

    add_concurrent_partitioned_foreign_key(
      :ai_conversation_threads, :organizations,
      column: :organization_id,
      on_delete: :cascade,
      name: THREADS_TO_ORGANIZATIONS_FK
    )

    add_concurrent_partitioned_foreign_key(
      :ai_conversation_messages, :ai_conversation_threads,
      column: [:thread_id, :thread_last_updated_at],
      target_column: [:id, :last_updated_at],
      on_delete: :cascade,
      on_update: :cascade,
      name: MESSAGES_TO_THREADS_FK
    )

    add_concurrent_partitioned_foreign_key(:ai_conversation_messages, :ai_agent_versions,
      column: :agent_version_id,
      on_delete: :cascade,
      name: MESSAGES_TO_AGENT_VERSIONS_FK
    )

    add_concurrent_partitioned_foreign_key(
      :ai_conversation_messages, :organizations,
      column: :organization_id,
      on_delete: :cascade,
      name: MESSAGES_TO_ORGANIZATIONS_FK
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :ai_conversation_threads, :users, name: THREADS_TO_USERS_FK
      remove_foreign_key_if_exists :ai_conversation_threads, :organizations, name: THREADS_TO_ORGANIZATIONS_FK
      remove_foreign_key_if_exists :ai_conversation_messages, :ai_conversation_threads, name: MESSAGES_TO_THREADS_FK
      remove_foreign_key_if_exists :ai_conversation_messages, :ai_agent_versions, name: MESSAGES_TO_AGENT_VERSIONS_FK
      remove_foreign_key_if_exists :ai_conversation_messages, :organizations, name: MESSAGES_TO_ORGANIZATIONS_FK
    end
  end
end
