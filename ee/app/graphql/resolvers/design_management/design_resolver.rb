# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class DesignResolver < BaseResolver
      argument :ids,
               [GraphQL::ID_TYPE],
               required: false,
               description: 'Filters designs by their ID'
      argument :filenames,
               [GraphQL::STRING_TYPE],
               required: false,
               description: 'Filters designs by their filename'
      argument :at_version,
               GraphQL::ID_TYPE,
               required: false,
               description: 'Filters designs to only those that existed at the version. ' \
                            'If argument is omitted or nil then all designs will reflect the latest version'

      def resolve(**args)
        find_designs(args)
      end

      def version(args)
        args[:at_version] ? GitlabSchema.object_from_id(args[:at_version])&.sync : nil
      end

      def design_ids(args)
        args[:ids] ? args[:ids].map { |id| GlobalID.parse(id).model_id } : nil
      end

      def find_designs(args)
        ::DesignManagement::DesignsFinder.new(
          object.issue,
          context[:current_user],
          ids: design_ids(args),
          filenames: args[:filenames],
          visible_at_version: version(args)
        ).execute
      end
    end
  end
end
