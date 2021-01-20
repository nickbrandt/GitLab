# frozen_string_literal: true

module Resolvers
  class ProjectMergeRequestsResolver < MergeRequestsResolver
    type ::Types::MergeRequestType.connection_type, null: true
    accept_assignee
    accept_author
    accept_reviewer

    def resolve(**args)
      scope = super

      if only_count_is_selected_with_merged_at_filter?(args) && Feature.enabled?(:optimized_merge_request_count_with_merged_at_filter)
        MergeRequest::MetricsFinder
          .new(current_user, args.merge(target_project: project))
          .execute
      else
        scope
      end
    end

    def only_count_is_selected_with_merged_at_filter?(args)
      return unless lookahead

      argument_names = args.keys
      argument_names.delete(:lookahead)
      argument_names.delete(:sort)
      argument_names.delete(:merged_before)
      argument_names.delete(:merged_after)

      # Detecting a specific query pattern:
      # mergeRequests(mergedAfter: "X", mergedBefore: "Y") {
      #   count
      # }
      lookahead.selects?(:count) &&
        lookahead.selections.size == 1 && # no other nodes are selected
        (args[:merged_after] || args[:merged_before]) &&
        argument_names.empty? # no extra filtering arguments are provided
    end
  end
end
