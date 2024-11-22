# frozen_string_literal: true

module Gitlab
  module InternalEventsTracking
    module ClassMethods
      def track_internal_event(event_name, event_args)
        Gitlab::InternalEvents.track_event(event_name, category: name, **event_args)
      end
    end

    def self.included(base)
      base.extend(ClassMethods) # Add class methods to the including class
    end

    def track_internal_event(event_name, event_args)
      self.class.track_internal_event(event_name, event_args)
    end
  end
end
