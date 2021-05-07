# frozen_string_literal: true

module Resolvers
  module Ci
    class RunnersResolver < BaseResolver
      type Types::Ci::RunnerType.connection_type, null: true

      argument :status, ::Types::Ci::RunnerStatusEnum,
               required: false,
               description: 'Filter runners by status.'

      argument :tag_list, [GraphQL::STRING_TYPE],
               required: false,
               description: 'Filter by tags associated with the runner (comma-separated or array).'

      argument :sort, GraphQL::STRING_TYPE,
               required: false,
               description: 'Sort order of results.'

      def resolve(**args)
        ::Ci::RunnersFinder
          .new(current_user: current_user, params: runners_finder_params(args))
          .execute
      end

      private

      def runners_finder_params(params)
        {
          status_status: params[:status]&.to_s,
          tag_name: params[:tag_list],
          search: params[:search],
          sort: params[:sort]&.to_s,
          disable_pagination: true
        }.compact
      end
    end
  end
end
