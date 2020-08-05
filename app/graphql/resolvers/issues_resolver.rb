# frozen_string_literal: true

module Resolvers
  class IssuesResolver < BaseResolver
    prepend Resolvers::IssueResolverFields

    argument :state, Types::IssuableStateEnum,
              required: false,
              description: 'Current state of this issue'
    argument :sort, Types::IssueSortEnum,
              description: 'Sort issues by this criteria',
              required: false,
              default_value: 'created_desc'

    type Types::IssueType, null: true

    NON_STABLE_CURSOR_SORTS = %i[priority_asc priority_desc
                                 label_priority_asc label_priority_desc
                                 milestone_due_asc milestone_due_desc].freeze

    def resolve(**args)
      # The project could have been loaded in batch by `BatchLoader`.
      # At this point we need the `id` of the project to query for issues, so
      # make sure it's loaded and not `nil` before continuing.
      parent = object.respond_to?(:sync) ? object.sync : object
      return Issue.none if parent.nil?

      # Will need to be be made group & namespace aware with
      # https://gitlab.com/gitlab-org/gitlab-foss/issues/54520
      args[:iids] ||= [args.delete(:iid)].compact if args[:iid]
      args[:attempt_project_search_optimizations] = true if args[:search].present?

      finder = IssuesFinder.new(current_user, args)
      issues = Gitlab::Graphql::Loaders::IssuableLoader.new(parent, finder).batching_find_all

      if non_stable_cursor_sort?(args[:sort])
        # Certain complex sorts are not supported by the stable cursor pagination yet.
        # In these cases, we use offset pagination, so we return the correct connection.
        Gitlab::Graphql::Pagination::OffsetActiveRecordRelationConnection.new(issues)
      else
        issues
      end
    end

    def self.resolver_complexity(args, child_complexity:)
      complexity = super
      complexity += 2 if args[:labelName]

      complexity
    end

    def non_stable_cursor_sort?(sort)
      NON_STABLE_CURSOR_SORTS.include?(sort)
    end
  end
end

Resolvers::IssuesResolver.prepend_if_ee('::EE::Resolvers::IssuesResolver')
