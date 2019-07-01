# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class DesignResolver < BaseResolver
      argument :at_version,
               GraphQL::ID_TYPE,
               required: false,
               description: 'Filters designs to only those that existed at the version. ' \
                            'If argument is omitted or nil then all designs will reflect the latest version.'

      def resolve(at_version: nil)
        version = at_version ? GitlabSchema.object_from_id(at_version) : nil

        ::DesignManagement::DesignsFinder.new(
          object.issue,
          context[:current_user],
          visible_at_version: version
        ).execute
      end
    end
  end
end
