# frozen_string_literal: true

class CreatePackagesDependencyFirewallSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.4'

  TABLE_NAME = :packages_dependency_firewall_settings

  def up
    with_lock_retries do
      create_table TABLE_NAME, id: false, if_not_exists: true do |t|
        t.timestamps_with_timezone null: false

        t.references :project,
          primary_key: true,
          default: nil,
          index: false,
          foreign_key: { to_table: :projects, on_delete: :cascade }

        t.boolean :dependency_scanning_check_enabled, default: false, null: false
        t.integer :dependency_scanning_check_threshold, default: 0, null: false, limit: 2
        t.boolean :dependency_scanning_check_quarantine, default: false, null: false
        t.boolean :dependency_scanning_check_create_issue, default: false, null: false

        t.boolean :deny_regex_check_enabled, default: false, null: false
        t.text :deny_regex_check_list, null: true, limit: 512
        t.boolean :deny_regex_check_quarantine, default: false, null: false
        t.boolean :deny_regex_check_create_issue, default: false, null: false

        t.boolean :owasp_dep_scan_check_enabled, default: false, null: false
        t.boolean :owasp_dep_scan_check_quarantine, default: false, null: false
        t.boolean :owasp_dep_scan_check_create_issue, default: false, null: false
      end
    end
  end

  def down
    drop_table TABLE_NAME
  end
end
