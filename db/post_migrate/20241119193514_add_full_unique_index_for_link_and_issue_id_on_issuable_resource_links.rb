# frozen_string_literal: true

class AddFullUniqueIndexForLinkAndIssueIdOnIssuableResourceLinks < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  # DEPENDENT_BATCHED_BACKGROUND_MIGRATIONS = [
  #   20240908225334,
  #   20241111055711
  # ]
  milestone '17.7'

  # gitlabhq_development=# \d issuable_resource_links
  #   Table "public.issuable_resource_links"
  #   Column   |           Type           | Collation | Nullable |                       Default
  # ------------+--------------------------+-----------+----------+-----------------------------------------------------
  # id         | bigint                   |           | not null | nextval('issuable_resource_links_id_seq'::regclass)
  # issue_id   | bigint                   |           | not null |
  # link_text  | text                     |           |          |
  # link       | text                     |           | not null |
  # link_type  | smallint                 |           | not null | 0
  # created_at | timestamp with time zone |           | not null |
  # updated_at | timestamp with time zone |           | not null |
  # is_unique  | boolean                  |           |          |
  # Indexes:
  #    "issuable_resource_links_pkey" PRIMARY KEY, btree (id)
  #    "index_issuable_resource_links_on_issue_id" btree (issue_id)
  #    "index_unique_issuable_resource_links_on_issue_id_and_link" UNIQUE, btree (issue_id, link)
  #    "index_unique_issuable_resource_links_on_unique_issue_link" UNIQUE, btree (issue_id, link) WHERE is_unique
  # Check constraints:
  #    "check_67be6729db" CHECK (char_length(link) <= 2200)
  #    "check_b137147e0b" CHECK (char_length(link_text) <= 255)
  # Foreign-key constraints:
  #    "fk_rails_3f0ec6b1cf" FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE
  DUPLICATE_INDEX_NAME = 'index_issuable_resource_links_on_issue_id'
  PARTIAL_INDEX_NAME = 'index_unique_issuable_resource_links_on_unique_issue_link'
  FULL_INDEX_NAME = 'index_unique_issuable_resource_links_on_issue_id_and_link'

  def up
    remove_concurrent_index_by_name :issuable_resource_links, DUPLICATE_INDEX_NAME
    remove_concurrent_index_by_name :issuable_resource_links, PARTIAL_INDEX_NAME
    add_concurrent_index :issuable_resource_links, %i[issue_id link], unique: true, name: FULL_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issuable_resource_links, FULL_INDEX_NAME
    add_concurrent_index :issuable_resource_links,
      %i[issue_id link],
      unique: true,
      where: "is_unique",
      name: PARTIAL_INDEX_NAME
    add_concurrent_index :issuable_resource_links,
      %i[issue_id],
      name: DUPLICATE_INDEX_NAME
  end
end
