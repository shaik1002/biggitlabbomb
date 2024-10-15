# frozen_string_literal: true

module Packages
  class CreateEventService < BaseService
    INTERNAL_EVENTS_NAMES = {
      'pull_package' => 'pull_package_from_registry'
    }.freeze

    def execute
      ::Packages::Event.unique_counters_for(event_scope, event_name, originator_type).each do |event_name|
        ::Gitlab::UsageDataCounters::HLLRedisCounter.track_event(event_name, values: current_user.id)
      end

      if INTERNAL_EVENTS_NAMES.key?(event_name)
        user = current_user if current_user.is_a?(User)

        Gitlab::InternalEvents.track_event(
          INTERNAL_EVENTS_NAMES[event_name],
          user: user,
          project: project,
          namespace: params[:namespace],
          additional_properties: {
            label: event_scope.to_s,
            property: originator_type.to_s
          }
        )
      else
        ::Packages::Event.counters_for(event_scope, event_name, originator_type).each do |event_name|
          ::Gitlab::UsageDataCounters::PackageEventCounter.count(event_name)
        end
      end
    end

    def originator_type
      case current_user
      when User
        :user
      when DeployToken
        :deploy_token
      else
        :guest
      end
    end

    private

    def event_scope
      @event_scope ||= scope.is_a?(::Packages::Package) ? scope.package_type : scope
    end

    def scope
      params[:scope]
    end

    def event_name
      params[:event_name]
    end
  end
end
