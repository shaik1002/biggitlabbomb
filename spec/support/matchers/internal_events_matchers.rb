# frozen_string_literal: true

# Matchers for Internal Event & Metric instrumentation.
#
# -- #trigger_internal_events -------
#       Use: Asserts that one or more internal events were triggered with
#            the correct properties and behavior. By default, expects the
#            provided events to be triggered only once.
#     Scope: Internal events only. RedisHll not supported directly.
#   Options: - Provide one or more event actions from config/events/ definitions as params.
#            - Accepts same chain methods as `receive` matcher (#once, #at_most, etc).
#            - Composable with other matchers that act on a block (like `change` matcher).
#            - Negated matcher (#not_trigger_internal_events) does not accept message chains.
#   Example:
#            expect { subject }
#              .to trigger_internal_events('web_ide_viewed')
#              .with(user: user, project: project, namespace: namespace)
#
# -- #increment_usage_metrics -------
#       Use: Asserts that one or more usage metric was incremented by the right value.
#            By default, expects the provided metrics to be incremented by 1.
#     Scope: For metrics from internal events or instrumentation classes.
#   Options: - Provide one or more metric key_paths from config/metrics/ definitions as params.
#            - Accepts same chain methods as `change` matcher (#by, #from, #to, etc).
#            - Composable with other matchers that act on a block (like `change` matcher).
#            - Negated matcher (#not_increment_usage_metrics) does not accept message chains.
#   Example:
#            expect { subject }.to increment_usage_metrics('counts.deployments')
#
# -- MORE USAGE EXAMPLES -------
#
# expect { 'do the thing' }.to trigger_internal_events('mr_created')
#                             .with(user: user, project: project, namespace: namepsace)
#                          .and increment_usage_metrics('counts.deployments')
#                          .and not_trigger_internal_events('pipeline_started')
#
# expect { 'do the thing' }.not_to trigger_internal_events('mr_created', 'member_role_created')
#
# expect { subject }
#   .to trigger_internal_events('mr_created', 'member_role_created')
#   .with(user: user, project: project, category: category, additional_properties: { label: label } )
#   .exactly(3).times
#
# expect { subject }
#   .to trigger_internal_events('mr_created')
#     .with(user: user, project: project, category: category, additional_properties: { label: label } )
#   .and increment_usage_metrics('counts.deployments')
#     .at_least(:once)
#   .and change { mr.notes.count }.by(1)
#
module InternalEventsMatchHelpers
  def supports_block_expectations?
    true
  end

  def supports_value_expectations?
    false
  end

  # Reuse the same spy instance across any chained matchers so that expected `receive`
  # counts are accurately tracked and reported
  def find_or_init_instance_spy(expected_klass, &)
    existing_spies = RSpec::Mocks.space.proxies.values.filter_map do |proxy|
      klass = proxy.instance_variable_get(:@doubled_module)&.send(:object)
      spy = proxy.instance_variable_get(:@object)

      spy if klass == expected_klass
    end

    existing_spies.first || instance_spy(expected_klass).tap(&)
  end

  def check_if_params_provided!(param_name, param_values)
    return if param_values&.any?

    raise ArgumentError, "#{name} matcher requires #{param_name} argument"
  end

  def check_if_events_exist!(event_names)
    event_names.each do |event_name|
      next if Gitlab::Tracking::EventDefinition.internal_event_exists?(event_name)

      raise ArgumentError, "Unknown event '#{event_name}'! #{name} matcher accepts only existing events"
    end
  end

  def apply_chain_methods(base_matcher, chained_methods)
    return base_matcher unless chained_methods&.any?

    chained_methods.reduce(base_matcher) do |matcher, args|
      matcher.send(*args)
    end
  end
end

RSpec::Matchers.define :trigger_internal_events do |*event_names|
  include InternalEventsMatchHelpers

  def supports_value_expectations?
    true
  end

  description { "trigger the internal events: #{event_names.join(', ')}" }

  failure_message { @failure_message }
  failure_message_when_negated { @failure_message }

  chain :with do |args|
    @properties ||= {
      category: described_class&.name,
      **args
    }
    @properties[:namespace] ||= @properties[:project]&.namespace
    @additional_properties ||= @properties.fetch(:additional_properties, {})
  end

  %i[once twice thrice never at_most at_least times time exactly].each do |message|
    chain message do |*values|
      @chained_methods ||= []
      @chained_methods << [message, *values]
    end
  end

  # Accepts same args as `Capybara::Node::Finders#find`
  # See https://www.rubydoc.info/gems/capybara/Capybara/Node/Finders#find-instance_method
  chain :on_click do |selector|
    @on_load = false
    @data_attribute_target = selector
  end

  chain :on_load do
    @on_load = true
    @data_attribute_target = nil
  end

  match do |input|
    setup_match_context(event_names)
    check_if_params_provided!(:events, @event_names)
    check_if_events_exist!(@event_names)
    handle_input(input)
  end

  match_when_negated do |input|
    setup_match_context(event_names)
    check_if_events_exist!(@event_names)
    handle_input(input, negate: true)
  end

  private

  def setup_match_context(event_names)
    @event_names = event_names.flatten
    @properties ||= {}
  end

  def handle_input(input, negate: false)
    result = case input
             when Proc
               negate ? expect_no_events_to_fire(input) : expect_events_to_fire(input)
             when Capybara::Node::Simple
               expect_data_attributes(input, negate: negate)
             when String
               expect_data_attributes(input, matcher: :have, negate: negate)
             else
               raise_argument_type_error!
             end

    negate ? true : result
  end

  def expect_no_events_to_fire(proc)
    # rubocop:disable RSpec/ExpectGitlabTracking -- Supersedes the #expect_snowplow_event helper for internal events
    allow(Gitlab::Tracking).to receive(:event).and_call_original
    allow(Gitlab::InternalEvents).to receive(:track_event).and_call_original
    # rubocop:enable RSpec/ExpectGitlabTracking

    collect_expectations do |event_name|
      [
        expect_no_snowplow_event(event_name),
        expect_no_internal_event(event_name)
      ]
    end

    proc.call

    verify_expectations

    true
  rescue RSpec::Mocks::MockExpectationError => e
    @failure_message = e.message
    false
  ensure
    # prevent expectations from being satisfied outside of the block scope
    unstub_expectations
  end

  def expect_events_to_fire(proc)
    check_block_input!

    @chained_methods ||= [[:once]]

    allow(Gitlab::InternalEvents).to receive(:track_event).and_call_original
    allow(Gitlab::Redis::HLL).to receive(:add).and_call_original

    collect_expectations do |event_name|
      [
        expect_internal_event(event_name),
        expect_snowplow(event_name),
        expect_product_analytics(event_name)
      ]
    end

    proc.call

    verify_expectations

    true
  rescue RSpec::Mocks::MockExpectationError => e
    @failure_message = e.message
    false
  ensure
    # prevent expectations from being satisfied outside of the block scope
    unstub_expectations
  end

  # Keep this in sync with the constants in app/assets/javascripts/tracking/constants.js
  def expect_data_attributes(node, matcher: :match, negate: false)
    check_node_input!

    element = find_target_element(node)

    verify_tracking_attributes(element, matcher, negate: negate)

    true
  rescue StandardError => e
    @failure_message = e.message
    false
  end

  def find_target_element(node)
    @data_attribute_target.present? ? node.find("[href='#{@data_attribute_target}']") : node
  end

  def expect_to_have_attribute(element, selector, matcher)
    verify_matcher_support!(matcher)

    expect(element).to send(:"#{matcher}_css", selector)
  end

  def expect_not_to_have_attribute(element, selector, matcher)
    verify_matcher_support!(matcher)

    expect(element).not_to send(:"#{matcher}_css", selector)
  end

  def verify_tracking_attributes(element, matcher, negate: false)
    verify_load_tracking(element, matcher, negate) if @on_load
    verify_event_tracking(element, matcher, negate)
    verify_property_tracking(element, matcher, negate)
  end

  def verify_load_tracking(element, matcher, negate)
    verify_attribute(element, build_tracking_selector('load', 'true'), matcher, negate)
  end

  def verify_event_tracking(element, matcher, negate)
    @event_names.each do |event_name|
      verify_attribute(element, build_tracking_selector('tracking', event_name), matcher, negate)
    end
  end

  def verify_property_tracking(element, matcher, negate)
    @additional_properties.slice(:label, :property, :value).compact.each do |(property, value)|
      verify_attribute(element, build_tracking_selector(property, value), matcher, negate)
    end
  end

  def build_tracking_selector(attribute, value)
    if attribute == 'load'
      '[data-event-tracking-load="true"]'
    else
      "[data-event-#{attribute}='#{value}']"
    end
  end

  def verify_attribute(element, selector, matcher, negate)
    method = negate ? :expect_not_to_have_attribute : :expect_to_have_attribute
    send(method, element, selector, matcher)
  end

  def verify_matcher_support!(matcher)
    return if %i[have match].include?(matcher)

    raise ArgumentError, "Unsupported matcher: #{matcher}"
  end

  def receive_expected_count_of(message)
    apply_chain_methods(receive(message), @chained_methods)
  end

  def expect_internal_event(event_name)
    expect(Gitlab::InternalEvents).to receive_expected_count_of(:track_event).with(event_name, any_args)
  end

  def expect_no_internal_event(event_name)
    expect(Gitlab::InternalEvents).not_to receive(:track_event).with(event_name, anything)
  end

  def expect_snowplow(event_name)
    category = @properties[:category] || 'InternalEventTracking'

    return expect_any_snowplow_call(category.to_s, event_name) if @properties.empty?

    expect(snowplow_spy).to receive_expected_count_of(:event).with(
      category.to_s,
      event_name,
      include(
        context: contain_exactly(
          standard_context,
          service_ping_context_for(event_name)
        ),
        **@additional_properties.slice(:label, :property, :value).compact
      )
    )
  end

  def standard_context
    have_attributes(
      class: SnowplowTracker::SelfDescribingJson,
      to_json: include(
        schema: Gitlab::Tracking::StandardContext::GITLAB_STANDARD_SCHEMA_URL,
        data: include(
          user_id: id_for(:user),
          project_id: id_for(:project),
          namespace_id: id_for(:namespace),
          feature_enabled_by_namespace_ids: @properties[:feature_enabled_by_namespace_ids],
          **{ extra: @additional_properties.except(:label, :property, :value) || {} }
        )
      )
    )
  end

  def service_ping_context_for(event_name)
    have_attributes(
      class: SnowplowTracker::SelfDescribingJson,
      to_json: include(
        schema: Gitlab::Tracking::ServicePingContext::SCHEMA_URL,
        data: include(event_name: event_name)
      )
    )
  end

  def expect_any_snowplow_call(category, event_name)
    expect(snowplow_spy).to receive_expected_count_of(:event)
      .with(category, event_name, anything)
  end

  def expect_no_snowplow_event(event_name)
    # rubocop:disable RSpec/ExpectGitlabTracking -- Supercedes the #expect_snowplow_event helper for internal events
    expect(Gitlab::Tracking).not_to receive(:event).with(anything, event_name, any_args)
    # rubocop:enable RSpec/ExpectGitlabTracking
  end

  def expect_product_analytics(event_name)
    return expect_any_product_analytics_call(event_name) if @properties.none?

    expected_context = { project_id: id_for(:project), namespace_id: id_for(:namespace) }
    additional_properties = @additional_properties.slice(:label, :property, :value)
    expected_context[:additional_properties] = additional_properties if additional_properties.any?

    expect(product_analytics_spy).to receive_expected_count_of(:track).with(
      event_name,
      include(**expected_context)
    )
  end

  def expect_any_product_analytics_call(event_name)
    expect(product_analytics_spy).to receive_expected_count_of(:track).with(
      event_name,
      include(project_id: anything, namespace_id: anything)
    )
  end

  def id_for(property)
    @properties[property]&.id
  end

  def snowplow_spy
    find_or_init_instance_spy(Gitlab::Tracking::Destinations::Snowplow) do |spy|
      allow(Gitlab::Tracking).to receive(:tracker).and_return(spy)
    end
  end

  def product_analytics_spy
    find_or_init_instance_spy(GitlabSDK::Client) do |spy|
      allow(Gitlab::InternalEvents).to receive(:gitlab_sdk_client).and_return(spy)
    end
  end

  def collect_expectations(&blk)
    # rubocop:disable Performance/FlatMap -- we want multiple flatten multiple levels deep
    @expectations = @event_names.map(&blk).flatten
    # rubocop:enable Performance/FlatMap
  end

  def verify_expectations
    @expectations&.each { |expectation| expectation.try(:verify_messages_received) }
  end

  def unstub_expectations
    @expectations&.each do |exp|
      doubled_module = exp.instance_variable_get(:@method_double)
      next unless doubled_module

      doubled_module.expectations.pop
    end
  end

  def check_block_input!
    return unless instance_variable_defined?(:@on_load)

    raise ArgumentError, "Chain methods :on_click, :on_load are only available for Capybara::Node::Simple type " \
      "arguments"
  end

  def check_node_input!
    return unless @chained_methods

    raise ArgumentError, "Chain methods #{@chained_methods.map(&:first).join(',')} are only available for " \
      "block arguments"
  end

  def raise_argument_type_error!
    raise ArgumentError, "#{name} matcher must assert on either a block (in most cases) or a " \
      "Capybara::Node::Simple (for ViewComponents and View specs)"
  end
end

RSpec::Matchers.alias_matcher :have_internal_tracking, :trigger_internal_events

RSpec::Matchers.define :increment_usage_metrics do |*key_paths|
  include InternalEventsMatchHelpers
  include ServicePingHelpers
  include UsageDataHelpers

  description { 'increments the counter for metrics' }

  %i[by by_at_least by_at_most from to].each do |message|
    chain message do |*values|
      @chained_methods ||= []
      @chained_methods << [message, *values]
    end
  end

  match do |proc|
    setup_context(key_paths, [[:by, 1]])

    build_matcher { |value_blk| change(&value_blk) }.matches?(proc)
  end

  match_when_negated do |proc|
    setup_context(key_paths)

    build_matcher { |value_blk| not_change(&value_blk) }.matches?(proc)
  end

  failure_message do
    increment = @chained_methods.flat_map { |*args| args }.join(' ')
    format_for_key_paths do |key_path, initial, final|
      "expected metric #{key_path} to be incremented #{increment}\n  ->  value went from #{initial} to #{final}"
    end
  end

  failure_message_when_negated do
    format_for_key_paths do |key_path, initial, final|
      "expected metric #{key_path} not to be incremented\n  ->  value went from #{initial} to #{final}"
    end
  end

  private

  # Init instance vars and validate inputs
  def setup_context(key_paths, default_chained_methods = [])
    @key_paths = key_paths.flatten
    @values ||= {}
    @chained_methods ||= default_chained_methods

    check_if_params_provided!(:key_paths, key_paths)
    stub_metric_timeframes
  end

  # Builds a single change matcher for verifying all
  # provided metric values, including chained expected counts
  def build_matcher
    @key_paths.reduce(nil) do |matcher, key_path|
      metric_definition = get_metric_definition(key_path)
      value_tracker = metric_value_tracker(key_path, metric_definition)
      change_matcher = yield(value_tracker)
      chained_matcher = apply_chain_methods(change_matcher, @chained_methods)

      matcher ? matcher.and(chained_matcher) : chained_matcher
    end
  end

  # Returns a proc that reads the current value of given metric,
  # to be passed to a change matcher
  def metric_value_tracker(key_path, metric_definition)
    proc do
      stub_usage_data_connections if metric_definition.data_source == 'database'

      metric = Gitlab::Usage::Metric.new(metric_definition)
      instrumentation_object = metric.send(:instrumentation_object)

      instrumentation_object.value.tap do |value|
        @values[key_path] ||= []
        @values[key_path] << value
      end
    end
  end

  def get_metric_definition(key_path)
    metric_definition = Gitlab::Usage::MetricDefinition.definitions[key_path]

    return metric_definition if metric_definition

    alt_definition_key = Gitlab::Usage::MetricDefinition.definitions.keys.sort.find { |key| key.include?(key_path) }

    raise ArgumentError, "Cannot find metric definition for '#{key_path}'!" unless alt_definition_key

    raise ArgumentError, "Cannot find metric definition for '#{key_path}' -- did you mean '#{alt_definition_key}'?"
  end

  def format_for_key_paths
    @key_paths.map do |key_path|
      initial, final = @values[key_path]

      yield(key_path, initial, final)
    end.join("\n")
  end
end

RSpec::Matchers.define_negated_matcher :not_trigger_internal_events, :trigger_internal_events
RSpec::Matchers.define_negated_matcher :not_increment_usage_metrics, :increment_usage_metrics
