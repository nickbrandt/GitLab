# frozen_string_literal: true

module Resolvers
  class EpicResolver < BaseResolver
    argument :iid, GraphQL::ID_TYPE,
             required: false,
             description: 'The IID of the epic, e.g., "1"'

    argument :iids, [GraphQL::ID_TYPE],
             required: false,
             description: 'The list of IIDs of epics, e.g., [1, 2]'

    type Types::EpicType, null: true

    def resolve(**args)
      return [] unless object.present?
      return [] unless epic_feature_enabled?

      find_epics(transform_args(args))
    end

    private

    def find_epics(args)
      EpicsFinder.new(context[:current_user], args).execute
    end

    def epic_feature_enabled?
      group.feature_available?(:epics)
    end

    def transform_args(args)
      transformed             = args.dup
      transformed[:group_id]  = group.id
      transformed[:parent_id] = parent.id if parent
      transformed[:iids]    ||= [args[:iid]].compact

      transformed
    end

    # `object` refers to the object we're currently querying on, and is usually a `Group`
    # when querying an Epic.  In the case of field that uses this resolver, for example
    # an Epic's `children` field, then `object` is an `EpicPresenter` (rather than an Epic).
    # But that's the epic we need in order to scope the find to only children of this epic,
    # using the `parent_id`
    def parent
      object if object.is_a?(EpicPresenter)
    end

    def group
      return object if object.is_a?(Group)

      parent.group
    end

    # If we're querying for multiple iids and selecting issues, then ideally
    # we want to batch the epic and issue queries into one to reduce N+1 and memory.
    # https://gitlab.com/gitlab-org/gitlab-ee/issues/11841
    # Until we do that, add in child_complexity for each iid requested
    # (minus one for the automatically added child_complexity in the BaseField)
    def self.resolver_complexity(args, child_complexity:)
      complexity  = super
      complexity += (args[:iids].count - 1) * child_complexity if args[:iids]

      complexity
    end
  end
end
