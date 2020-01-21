# frozen_string_literal: true

# This class represents an Epic's aggregate information (added up counts) about its child epics and direct issues

module Epics
  class EpicNode
    include AggregateConstants

    attr_reader :epic_id, :epic_state_id, :epic_info_flat_list, :parent_id,
                :direct_sums, # we calculate these and recursively add them
                :sum_total

    attr_accessor :child_ids

    def initialize(epic_id, flat_info_list)
      # epic aggregate records from the DB loader look like the following:
      # { 1 => [{iid: 1, epic_state_id: 1, issues_count: 1, issues_weight_sum: 2, parent_id: nil, state_id: 2}] ... }
      # They include the sum of each epic's direct issues, grouped by status,
      # so in order to get a sum of the entire tree, we have to add that up recursively
      @epic_id = epic_id
      @epic_info_flat_list = flat_info_list
      @child_ids = []
      @direct_sums = []

      set_epic_attributes(flat_info_list.first) # there will always be one
    end

    def assemble_issue_sums
      # this is a representation of the epic's
      # direct child issues and epics that have come from the DB
      [OPENED_ISSUE_STATE, CLOSED_ISSUE_STATE].each do |issue_state|
        matching_issue_state_entry = epic_info_flat_list.find do |epic_info_node|
          epic_info_node[:issues_state_id] == issue_state
        end || {}

        create_sum_if_needed(WEIGHT_SUM, issue_state, ISSUE_TYPE, matching_issue_state_entry.fetch(:issues_weight_sum, 0))
        create_sum_if_needed(COUNT, issue_state, ISSUE_TYPE, matching_issue_state_entry.fetch(:issues_count, 0))
      end
    end

    def assemble_epic_sums(children)
      [OPENED_EPIC_STATE, CLOSED_EPIC_STATE].each do |epic_state|
        create_sum_if_needed(COUNT, epic_state, EPIC_TYPE, children.select { |node| node.epic_state_id == epic_state }.count)
      end
    end

    def calculate_recursive_sums(tree)
      return sum_total if sum_total

      @sum_total = SumTotal.new
      child_ids.each do |child_id|
        child = tree[child_id]
        # get the child's totals, add to your own
        child_sums = child.calculate_recursive_sums(tree).sums
        sum_total.add(child_sums)
      end
      sum_total.add(direct_sums)
      sum_total
    end

    def aggregate_object_by(facet)
      sum_total.by_facet(facet)
    end

    def to_s
      { epic_id: @epic_id, parent_id: @parent_id, direct_sums: direct_sums, child_ids: child_ids }.to_json
    end

    alias_method :inspect, :to_s
    alias_method :id, :epic_id

    private

    def create_sum_if_needed(facet, state, type, value)
      return if value.nil? || value < 1

      direct_sums << Sum.new(facet, state, type, value)
    end

    def set_epic_attributes(record)
      @epic_state_id = record[:epic_state_id]
      @parent_id = record[:parent_id]
    end

    Sum = Struct.new(:facet, :state, :type, :value) do
      def inspect
        "<Sum facet=#{facet}, state=#{state}, type=#{type}, value=#{value}>"
      end
    end
  end
end
