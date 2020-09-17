# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    class TrackingEvent
      KNOWN_EVENTS_PATH = 'lib/gitlab/usage_data_counters/known_events.yml'.freeze

      # accept events from know_events.yml
      def initialize(event_name)
        event = event_for(event_name)

        raise UnknownEvent.new("Unknown event #{event_name}") unless event.present?

        @event_name = event_name
      end

      def flipper_id
        "#{self.class.name}:#{@event_name}"
      end

      class << self
        def all
          know_events.map { |event| event[:name] }
        end
      end

      private

      def self.known_events
        @known_events ||= YAML.load_file(Rails.root.join(KNOWN_EVENTS_PATH)).map(&:with_indifferent_access)
      end

      def event_for(event_name)
        self.class.known_events.find { |event| event[:name] == event_name }
      end
    end
  end
end
