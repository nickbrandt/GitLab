# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    class PackageUniqueCounter < HLLRedisCounter
      extend ::Gitlab::Utils::StrongMemoize

      EVENT_SCOPES = (::Packages::Package.package_types.keys + [:container, :tag]).freeze

      EVENT_TYPES = %i[
        push_package
        delete_package
        pull_package
        search_package
        list_package
        list_repositories
        delete_repository
        delete_tag
        delete_tag_bulk
        list_tags
        cli_metadata].freeze

      ORIGINATOR_TYPES = %i(user deploy_token).freeze

      # Override HLLRedisCounter.known_events to build a list of events dynamically
      # instead of loading from a file.
      # It builds a list of events by combining (scopes x type x originator type)
      def self.known_events
        strong_memoize(:known_events) do
          EVENT_SCOPES.each_with_object([]) do |event_scope, events|
            EVENT_TYPES.each do |event_type|
              ORIGINATOR_TYPES.each do |originator_type|
                events << {
                  name: "#{event_scope}_#{originator_type}_#{event_type}",
                  category: "#{event_scope}_packages",
                  aggregation: "weekly"
                }.with_indifferent_access
              end
            end
          end
        end
      end
    end
  end
end
