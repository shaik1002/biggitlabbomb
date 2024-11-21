# frozen_string_literal: true

class AddStreamingDestinationRefsToLegacyAuditDestinationModels < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.7'

  TABLES_INDEX_MAP = {
    audit_events_external_audit_event_destinations: "ext_audit_event_destinations",
    audit_events_instance_external_audit_event_destinations: "instance_ext_audit_event_destinations",
    audit_events_google_cloud_logging_configurations: "audit_events_gcp_configs",
    audit_events_instance_google_cloud_logging_configurations: "audit_events_instance_gcp_configs",
    audit_events_amazon_s3_configurations: "audit_events_aws_s3_configs",
    audit_events_instance_amazon_s3_configurations: "audit_events_instance_aws_s3_configs"
  }

  def up
    TABLES_INDEX_MAP.each do |table, table_index_name|
      add_column table, :stream_destination_ref, :bigint, null: true

      index_name = "uniq_idx_#{table_index_name}_stream_dest_ref"

      add_concurrent_index table, :stream_destination_ref, unique: true,
        name: index_name
    end
  end

  def down
    TABLES_INDEX_MAP.each do |table, table_index_name|
      index_name = "uniq_idx_#{table_index_name}_stream_dest_ref"

      remove_concurrent_index_by_name table, index_name
      remove_column table, :stream_destination_ref
    end
  end
end
