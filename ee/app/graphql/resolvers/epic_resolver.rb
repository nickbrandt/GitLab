# frozen_string_literal: true

module Resolvers
  class EpicResolver < BaseResolver
    argument :iid, GraphQL::ID_TYPE,
             required: false,
             description: 'The IID of the epic, e.g., "1"'

    argument :iids, [GraphQL::ID_TYPE],
             required: false,
             description: 'The list of IIDs of epics, e.g., [1, 2]'

    argument :state, Types::EpicStateEnum,
             required: false,
             description: 'Filter epics by state'

    argument :search, GraphQL::STRING_TYPE,
             required: false,
             description: 'Filter epics by title and description'

    argument :sort, Types::EpicSortEnum,
             required: false,
             description: 'List epics by sort order'

    argument :author_username, GraphQL::STRING_TYPE,
             required: false,
             description: 'Filter epics by author'

    argument :label_name, [GraphQL::STRING_TYPE],
             required: false,
             description: 'Filter epics by labels'

    argument :start_date, Types::TimeType,
             required: false,
             description: 'List epics within a time frame where epics.start_date is between start_date and end_date parameters (end_date parameter must be present)'

    argument :end_date, Types::TimeType,
             required: false,
             description: 'List epics within a time frame where epics.end_date is between start_date and end_date parameters (start_date parameter must be present)'

    type Types::EpicType, null: true

    def resolve(**args)
      @resolver_object = object.respond_to?(:sync) ? object.sync : object

      return [] unless resolver_object.present?
      return [] unless epic_feature_enabled?

      validate_date_params!(args)

      find_epics(transform_args(args))
    end

    private

    attr_reader :resolver_object

    def find_epics(args)
      EpicsFinder.new(context[:current_user], args).execute
    end

    def epic_feature_enabled?
      group.feature_available?(:epics)
    end

    def validate_date_params!(args)
      return unless args[:start_date].present? || args[:end_date].present?

      date_params_complete = args[:start_date] && args[:end_date]

      unless date_params_complete
        raise Gitlab::Graphql::Errors::ArgumentError, "Both start_date and end_date must be present."
      end
    end

    def transform_args(args)
      transformed             = args.dup
      transformed[:group_id]  = group.id
      transformed[:parent_id] = parent.id if parent
      transformed[:iids]    ||= [args[:iid]].compact

      transformed
    end

    # `resolver_object` refers to the object we're currently querying on, and is usually a `Group`
    # when querying an Epic.  In the case of field that uses this resolver, for example
    # an Epic's `children` field, then `resolver_object` is an `EpicPresenter` (rather than an Epic).
    # But that's the epic we need in order to scope the find to only children of this epic,
    # using the `parent_id`
    def parent
      resolver_object if resolver_object.is_a?(Epic)
    end

    def group
      return resolver_object if resolver_object.is_a?(Group)

      parent.group
    end

    # If we're querying for multiple iids and selecting issues, then ideally
    # we want to batch the epic and issue queries into one to reduce N+1 and memory.
    # https://gitlab.com/gitlab-org/gitlab/issues/11841
    # Until we do that, add in child_complexity for each iid requested
    # (minus one for the automatically added child_complexity in the BaseField)
    def self.resolver_complexity(args, child_complexity:)
      complexity  = super
      complexity += (args[:iids].count - 1) * child_complexity if args[:iids]

      complexity
    end
  end
end
