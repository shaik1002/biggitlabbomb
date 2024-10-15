# frozen_string_literal: true

# Helpers related to listing existing metric definitions
module InternalEventsCli
  module Helpers
    module MetricOptions
      EVENT_PHRASES = {
        'user' => "who triggered %s",
        'namespace' => "where %s occurred",
        'project' => "where %s occurred",
        nil => "%s occurrences"
      }.freeze

      def get_metric_options(events)
        actions = events.map(&:action)
        options = get_all_metric_options(actions)
        identifiers = get_identifiers_for_events(events)
        metric_name = format_metric_name_for_events(events)

        options = options.group_by do |metric|
          [
            metric.identifier.value,
            conflicting_metric_exists?(metric),
            metric.time_frame.value == 'all'
          ]
        end

        options.map do |(identifier, defined, _), metrics|
          format_metric_option(
            identifier,
            metric_name,
            metrics,
            defined: defined,
            supported: [*identifiers, nil].include?(identifier)
          )
        end
      end

      private

      def get_all_metric_options(actions)
        [
          Metric.new(actions: actions, time_frame: '28d', identifier: 'user'),
          Metric.new(actions: actions, time_frame: '7d', identifier: 'user'),
          Metric.new(actions: actions, time_frame: '28d', identifier: 'project'),
          Metric.new(actions: actions, time_frame: '7d', identifier: 'project'),
          Metric.new(actions: actions, time_frame: '28d', identifier: 'namespace'),
          Metric.new(actions: actions, time_frame: '7d', identifier: 'namespace'),
          Metric.new(actions: actions, time_frame: '28d'),
          Metric.new(actions: actions, time_frame: '7d'),
          Metric.new(actions: actions, time_frame: 'all')
        ]
      end

      def format_metric_name_for_events(events)
        return events.first.action if events.length == 1

        "any of #{events.length} events"
      end

      # Get only the identifiers in common for all events
      def get_identifiers_for_events(events)
        events.map(&:identifiers).reduce(&:&) || []
      end

      def conflicting_metric_exists?(new_metric)
        cli.global.metrics.any? do |existing_metric|
          existing_metric.actions == new_metric.actions &&
            existing_metric.time_frame == new_metric.time_frame.value &&
            existing_metric.identifier == new_metric.identifier.value
        end
      end

      def format_metric_option(identifier, event_name, metrics, defined:, supported:)
        time_frame = metrics.map { |metric| metric.time_frame.description }.join('/')
        unique_by = "unique #{identifier}s " if identifier
        event_phrase = EVENT_PHRASES[identifier] % event_name

        if supported && !defined
          time_frame = format_info(time_frame)
          unique_by = format_info(unique_by)
        end

        name = "#{time_frame} count of #{unique_by}[#{event_phrase}]"

        if supported && defined
          disabled = format_warning("(already defined)")
          name = format_help(name)
        elsif !supported
          disabled = format_warning("(#{identifier} unavailable)")
          name = format_help(name)
        end

        { name: name, value: metrics, disabled: disabled }.compact
      end
    end
  end
end
