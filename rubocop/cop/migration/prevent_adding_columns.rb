# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that prevents adding columns to wide tables.
      class PreventAddingColumns < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = <<~MSG
          `%s` is a large table with several columns, adding more should be avoided unless absolutely necessary.
          Consider storing the column in a different table or creating a new one.
          See https://docs.gitlab.com/ee/development/database/layout_and_access_patterns.html#data-model-trade-offs
        MSG

        DENYLISTED_METHODS = %i[
          add_column
          add_reference
          add_timestamps_with_timezone
        ].freeze

        def on_send(node)
          return unless in_migration?(node)

          method_name = node.children[1]
          table_name = node.children[2]

          return unless offense?(method_name, table_name)

          add_offense(node.loc.selector, message: format(MSG, table_name.value))
        end

        private

        def offense?(method_name, table_name)
          table_matches?(table_name) && DENYLISTED_METHODS.include?(method_name)
        end

        def table_matches?(table_name)
          return false unless valid_table_node?(table_name)

          table_value = table_name.value
          wide_or_over_limit_table?(table_value)
        end

        def wide_or_over_limit_table?(table_value)
          WIDE_TABLES.include?(table_value) || over_limit_tables.include?(table_value)
        end

        def valid_table_node?(table_name)
          table_name && table_name.type == :sym
        end
      end
    end
  end
end
