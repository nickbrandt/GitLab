# frozen_string_literal: true

module Geo
  class RepositoriesChangedEventStore < EventStore
    self.event_type = :repositories_changed_event

    attr_reader :geo_node

    def initialize(geo_node)
      @geo_node = geo_node
    end

    private

    def build_event
      Geo::RepositoriesChangedEvent.new(geo_node: geo_node)
    end
  end
end
