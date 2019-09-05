# frozen_string_literal: true

module ContainerRegistry
  class EventHandler
    attr_reader :events

    def initialize(events)
      @events = events
    end

    def execute
      events.each do |event|
        handle_event(event) if %w(push delete).include?(event['action'])
      end
    end

    private

    def handle_event(event)
      return unless manifest_push?(event) || manifest_delete?(event)

      ::Geo::ContainerRepositoryUpdatedEventStore.new(find_repository!(event)).create!
    end

    def manifest_push?(event)
      event['target']['mediaType'] =~ /manifest/
    end

    def manifest_delete?(event)
      # There is no clear indication in the event structure when we delete a top-level manifest
      # except existance of "tag" key
      event['target'].has_key?('tag')
    end

    def find_repository!(event)
      repository_name = event['target']['repository']
      path = ContainerRegistry::Path.new(repository_name)
      ContainerRepository.find_by_path!(path)
    end
  end
end
