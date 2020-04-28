# frozen_string_literal: true

module Resolvers
  class IterationsResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource
    include TimeFrameArguments

    argument :state, Types::IterationStateEnum,
             required: false,
             description: 'Filter iterations by state'
    argument :title, GraphQL::STRING_TYPE,
             required: false,
             description: 'Fuzzy search by title'

    type Types::IterationType, null: true

    def resolve(**args)
      validate_timeframe_params!(args)

      authorize!

      iterations = IterationsFinder.new(iterations_finder_params(args)).execute

      Gitlab::Graphql::Pagination::OffsetActiveRecordRelationConnection.new(iterations)
    end

    private

    def iterations_finder_params(args)
      {
        state: args[:state] || 'all',
        start_date: args[:start_date],
        end_date: args[:end_date],
        search_title: args[:title]
      }.merge(parent_id_parameter)
    end

    def parent
      @parent ||= object.respond_to?(:sync) ? object.sync : object
    end

    def parent_id_parameter
      if parent.is_a?(Group)
        { group_ids: parent.id }
      elsif parent.is_a?(Project)
        { project_ids: parent.id }
      end
    end

    # IterationsFinder does not check for current_user permissions,
    # so for now we need to keep it here.
    def authorize!
      Ability.allowed?(context[:current_user], :read_iteration, parent) || raise_resource_not_available_error!
    end
  end
end
