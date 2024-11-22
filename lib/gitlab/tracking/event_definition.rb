# frozen_string_literal: true

module Gitlab
  module Tracking
    InvalidEventError = Class.new(RuntimeError)

    class EventDefinition
      attr_reader :path
      attr_reader :attributes

      class << self
        include Gitlab::Utils::StrongMemoize

        def definitions
          @definitions ||= paths.flat_map { |glob_path| load_all_from_path(glob_path) }
        end

        def internal_event_exists?(event_name)
          definitions
            .any? { |event| event.attributes[:internal_events] && event.action == event_name } ||
            Gitlab::UsageDataCounters::HLLRedisCounter.legacy_event?(event_name)
        end

        def find(event_name)
          strong_memoize_with(:find, event_name) do
            definitions.find { |definition| definition.action == event_name }
          end
        end

        private

        def paths
          @paths ||= [Rails.root.join('config', 'events', '*.yml'), Rails.root.join('ee', 'config', 'events', '*.yml')]
        end

        def load_from_file(path)
          definition = File.read(path)
          definition = YAML.safe_load(definition)
          definition.deep_symbolize_keys!

          self.new(path, definition)
        rescue StandardError => e
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(Gitlab::Tracking::InvalidEventError.new(e.message))
        end

        def load_all_from_path(glob_path)
          Dir.glob(glob_path).map { |path| load_from_file(path) }
        end
      end

      def initialize(path, opts = {})
        @path = path
        @attributes = opts
      end

      def to_h
        attributes
      end
      alias_method :to_dictionary, :to_h

      def yaml_path
        path.delete_prefix(Rails.root.to_s)
      end

      def event_selection_rules
        @event_selection_rules ||= find_event_selection_rules
      end

      def action
        attributes[:action]
      end

      private

      def find_event_selection_rules
        [
          Gitlab::Usage::EventSelectionRule.new(name: action, time_framed: false),
          Gitlab::Usage::EventSelectionRule.new(name: action, time_framed: true),
          *Gitlab::Usage::MetricDefinition.all.flat_map do |metric_definition|
            metric_definition.event_selection_rules.select { |rule| rule.name == action }
          end
        ].uniq
      end
    end
  end
end
