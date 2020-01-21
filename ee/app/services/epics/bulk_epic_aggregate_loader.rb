# frozen_string_literal: true

module Epics
  class BulkEpicAggregateLoader
    include AggregateConstants

    # This class retrieves each epic and its child epics recursively
    # It allows us to recreate the epic tree structure in POROs
    def initialize(epic_ids:)
      @results = {}
      @target_epic_ids = epic_ids.present? ? [epic_ids].flatten.compact : []
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def execute
      return {} unless target_epic_ids.any?

      # We do a left outer join in order to capture epics with no issues
      # This is so we can aggregate the epic counts for every epic
      raw_results = ::Gitlab::ObjectHierarchy.new(Epic.where(id: target_epic_ids)).base_and_descendants
        .left_joins(epic_issues: :issue)
        .group("issues.state_id", "epics.id", "epics.iid", "epics.parent_id", "epics.state_id")
        .select("epics.id, epics.iid, epics.parent_id, epics.state_id AS epic_state_id, issues.state_id AS issues_state_id, COUNT(issues) AS issues_count, SUM(COALESCE(issues.weight, 0)) AS issues_weight_sum")

      raw_results = raw_results.map(&:attributes).map(&:with_indifferent_access)
      group_by_epic_id(raw_results)
      @results
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    attr_reader :target_epic_ids, :results

    def group_by_epic_id(raw_records)
      # for each id, populate with matching records
      # change from a series of { id: x ... } to { x => [{...}, {...}] }
      raw_records.map { |r| r[:id] }.uniq.each do |epic_id|
        records = []
        matching_records = raw_records.select { |record| record[:id] == epic_id }
        matching_records.each do |record|
          records << record.except(:id).to_h.with_indifferent_access
        end
        @results[epic_id] = records
      end
    end
  end
end
