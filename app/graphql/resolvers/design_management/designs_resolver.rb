# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class DesignsResolver < BaseResolver
      argument :ids,
               [::Types::GlobalIDType[::DesignManagement::Design]],
               required: false,
               description: 'Filters designs by their ID'
      argument :filenames,
               [GraphQL::STRING_TYPE],
               required: false,
               description: 'Filters designs by their filename'
      argument :at_version, ::Types::GlobalIDType[::DesignManagement::Version],
               required: false,
               description: 'Filters designs to only those that existed at the version. ' \
                            'If argument is omitted or nil then all designs will reflect the latest version'

      def self.single
        ::Resolvers::DesignManagement::DesignResolver
      end

      def resolve(ids: nil, filenames: nil, at_version: nil)
        ::DesignManagement::DesignsFinder.new(
          issue,
          current_user,
          ids: design_ids(ids),
          filenames: filenames,
          visible_at_version: version(at_version)
        ).execute
      end

      private

      def version(at_version)
        return unless at_version

        GitlabSchema.object_from_id(at_version, expected_type: ::DesignManagement::Version)&.sync
      end

      def design_ids(gids)
        Array.wrap(gids).compact.map(&:model_id).presence
      end

      def issue
        object.issue
      end
    end
  end
end
