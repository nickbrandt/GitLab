# frozen_string_literal: true

module ContainerRegistry
  class EventHandler
    attr_reader :events

    def initialize(events)
      @events = events
    end

    def execute
      events.each do |event|
        handle_push_event(event) if event['action'] == 'push'
      end
    end

    private

    def handle_push_event(event)
      return unless manifest_push?(event)

      ::Geo::ContainerRepositoryUpdatedEventStore.new(find_repository!(event)).create!
    end

    def manifest_push?(event)
      event['target']['mediaType'] =~ /manifest/
    end

    def find_repository!(event)
      repository_name = event['target']['repository']
      path = ContainerRegistry::Path.new(repository_name)
      ContainerRepository.find_by_path!(path)
    end
  end
end
