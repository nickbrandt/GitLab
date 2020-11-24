# frozen_string_literal: true

module Gitlab
  class UsageData
    class Event # < Hashie::Mash
      EventError = Class.new(StandardError)
      UnknownEvent = Class.new(EventError)

      # KNOWN_EVENTS_PATH = File.expand_path('known_events/*.yml', __dir__)
      KNOWN_EVENTS_PATH = File.join(Rails.root, 'lib', 'gitlab', 'usage_data_counters', 'known_events', '*.yml')
      class << self
        def categories
          @categories ||= all.map { |event| event[:category] }.uniq
        end

        # @param category [String] the category name
        # @return [Array<String>] list of event names for given category
        def events_for_category(category)
          all.select { |event| event[:category] == category.to_s }.map { |event| event[:name] }
        end

        def known?(event_name)
          event_for(event_name).present?
        end

        def all
          @all ||= load_events(KNOWN_EVENTS_PATH)
        end

        def event_for(event_name)
          all.find { |event| event[:name] == event_name.to_s }
        end

        def events_for(event_names)
          all.select { |event| event_names.include?(event[:name]) }
        end

        def known_events_names
          all.map { |event| event[:name] }
        end

        private

        def load_events(wildcard)
          Dir[wildcard].each_with_object([]) do |path, events|
            events.push(*load_yaml_from_path(path))
          end
        end

        def load_yaml_from_path(path)
          YAML.safe_load(File.read(path))&.map(&:with_indifferent_access)
        end
      end
    end
  end
end
