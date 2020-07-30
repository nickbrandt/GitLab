# frozen_string_literal: true

module Resolvers
  class IssueStatusCountsResolver < BaseResolver
    prepend Resolvers::IssueResolverFields

    type Types::IssueStatusCountsType, null: true

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

      Gitlab::IssuablesCountForState.new(finder, parent)
    end
  end
end
