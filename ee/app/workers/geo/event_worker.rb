# frozen_string_literal: true

module Geo
  class EventWorker
    include ApplicationWorker
    include GeoQueue

    sidekiq_options retry: 3, dead: false

    def perform(replicable_name, event_name, payload)
      Geo::EventService.new(replicable_name, event_name, payload).execute
    end
  end
end
