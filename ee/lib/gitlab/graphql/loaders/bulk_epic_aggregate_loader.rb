# frozen_string_literal: true

module Gitlab
  module Graphql
    module Loaders
      class BulkEpicAggregateLoader
        include ::Gitlab::Graphql::Aggregations::Epics::Constants

        attr_reader :target_epic_ids, :results

        # This class retrieves each epic and its child epics recursively
        # It allows us to recreate the epic tree structure in POROs
        def initialize(epic_ids:)
          @results = {}
          @target_epic_ids = epic_ids
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def execute
          return {} unless target_epic_ids

          # We do a left outer join in order to capture epics with no issues
          # This is so we can aggregate the epic counts for every epic
          raw_results = ::Gitlab::ObjectHierarchy.new(Epic.where(id: target_epic_ids)).base_and_descendants
            .left_joins(epic_issues: :issue)
            .group("issues.state_id", "epics.id", "epics.iid", "epics.parent_id", "epics.state_id")
            .select("epics.id, epics.iid, epics.parent_id, epics.state_id AS epic_state_id, issues.state_id AS issues_state_id, COUNT(issues) AS issues_count, SUM(COALESCE(issues.weight, 0)) AS issues_weight_sum")

          raw_results = raw_results.map(&:attributes).map(&:with_indifferent_access)
          @results = raw_results.group_by { |record| record[:id] }
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
