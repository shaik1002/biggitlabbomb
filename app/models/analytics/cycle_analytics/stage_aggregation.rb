# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class StageAggregation < ApplicationRecord
      include Analytics::CycleAnalytics::Parentable

      STATS_SIZE_LIMIT = 10

      belongs_to :stage, class_name: 'Analytics::CycleAnalytics::Stage', optional: false # rubocop: disable Rails/InverseOf -- this relation is not present on Stage

      validates :runtimes_in_seconds, :processed_records,
        presence: true, length: { maximum: STATS_SIZE_LIMIT }, allow_blank: true

      def cursor_for(model)
        {
          updated_at: self["last_#{model.table_name}_updated_at"],
          id: self["last_#{model.table_name}_id"]
        }.compact
      end

      def set_cursor(model, cursor)
        self["last_#{model.table_name}_id"] = cursor[:id]
        self["last_#{model.table_name}_updated_at"] = cursor[:updated_at]
      end

      def refresh_last_run
        self.last_run_at = Time.current
      end

      def set_stats(runtime, processed_records)
        # We only store the last 10 data points
        self.runtimes_in_seconds = (runtimes_in_seconds + [runtime]).last(STATS_SIZE_LIMIT)
        self.processed_records = (self.processed_records + [processed_records]).last(STATS_SIZE_LIMIT)
      end
    end
  end
end
