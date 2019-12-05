# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class DesignResolver < BaseResolver
      argument :id, GraphQL::ID_TYPE,
               required: false,
               description: 'Find a design by its ID'

      argument :filename, GraphQL::STRING_TYPE,
               required: false,
               description: 'Find a design by its filename'

      def resolve(filename: nil, id: nil)
        params = if !filename.present? && !id.present?
                   error('one of id or filename must be passed')
                 elsif filename.present? && id.present?
                   error('only one of id or filename may be passed')
                 elsif filename.present?
                   { filenames: [filename] }
                 else
                   { ids: [GitlabSchema.parse_gid(id, expected_type: ::DesignManagement::Design).model_id] }
                 end

        build_finder(params).execute.first
      end

      private

      def issue
        object.issue
      end

      def user
        context[:current_user]
      end

      def build_finder(params)
        ::DesignManagement::DesignsFinder.new(issue, user, params)
      end

      def error(msg)
        raise ::Gitlab::Graphql::Errors::ArgumentError, 'one of id or filename must be passed'
      end
    end
  end
end
