require 'rails/generators'
require 'rails/generators/migration'

module Gitlab
  module ClickHouse
    class SiphonGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc "Clones a PostgreSQL table to ClickHouse to be used as siphon."

      argument :table_name, type: :string, required: true, desc: "The postgresql table to clone"

      def generate_clone_table_script
        timestamp = Time.current.strftime('%Y%m%d%H%M%S')

        migration_path = "db/click_house/migrate/main/#{timestamp}_create_siphon_#{table_name}.rb"

        template 'siphon_table.rb.template', migration_path
        puts "Generated ClickHouse siphon table migration at: #{migration_path}"
      end

      private

      def clickhouse_table_name
        "siphon_#{table_name}"
      end

      def table_definition
        # TODO - handle when primary key is not called id
        <<-TEXT.chomp
CREATE TABLE #{clickhouse_table_name}
      #{table_fields}
      ENGINE = ReplacingMergeTree()
      PRIMARY KEY (id)
      ORDER BY tuple()
        TEXT
      end

      # TODO - Transform PG types to CH types based on type OID
      # conversion table at https://gitlab.com/gitlab-org/architecture/gitlab-data-analytics/design-doc/-/blob/master/designs/logical_replication_mvp.md#data-serialization
      # TODO - Maybe allow to select only some fields?
      def table_fields
        fields =
          fields_metadata.map do |field|
            "#{field['field_name']} #{field['field_type']}"
          end

        <<-TEXT.chomp
  #{fields[0]}
        #{fields[1..].join("\n        ")}
        TEXT
      end

      def fields_metadata
        ActiveRecord::Base.connection.execute <<-SQL
          SELECT
              column_name AS field_name,
              data_type AS field_type,
              pg_type.oid AS field_type_id
          FROM
              information_schema.columns
          JOIN
              pg_catalog.pg_type ON pg_catalog.pg_type.typname = information_schema.columns.udt_name
          WHERE
              table_name = '#{table_name}';
        SQL
      end
    end
  end
end
