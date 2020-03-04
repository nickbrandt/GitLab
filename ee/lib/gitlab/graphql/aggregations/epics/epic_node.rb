# frozen_string_literal: true

# This class represents an Epic's aggregate information (added up counts) about its child epics and direct issues

module Gitlab
  module Graphql
    module Aggregations
      module Epics
        class EpicNode
          include ::Gitlab::Graphql::Aggregations::Epics::Constants
          include Gitlab::Utils::StrongMemoize

          attr_reader :epic_id, :epic_state_id, :epic_info_flat_list, :parent_id,
                      :direct_count_totals, :direct_weight_sum_totals, # only counts/weights of direct issues and child epic counts
                      :count_aggregate, :weight_sum_aggregate

          attr_accessor :children, :calculated_count_totals, :calculated_weight_sum_totals

          def initialize(epic_id, flat_info_list)
            # epic aggregate records from the DB loader look like the following:
            # { 1 => [{iid: 1, epic_state_id: 1, issues_count: 1, issues_weight_sum: 2, parent_id: nil, state_id: 2}] ... }
            # They include the sum of each epic's direct issues, grouped by status,
            # so in order to get a sum of the entire tree, we have to add that up recursively
            @epic_id = epic_id
            @epic_info_flat_list = flat_info_list
            @children = []
            @direct_count_totals = []
            @direct_weight_sum_totals = []

            set_epic_attributes(flat_info_list.first) # there will always be one
          end

          def assemble_issue_totals
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

          def assemble_epic_totals
            [OPENED_EPIC_STATE, CLOSED_EPIC_STATE].each do |epic_state|
              create_sum_if_needed(COUNT, epic_state, EPIC_TYPE, children.select { |node| node.epic_state_id == epic_state }.count)
            end
          end

          def aggregate_count(tree)
            strong_memoize(:count_aggregate) do
              calculate_recursive_sums(COUNT, tree)
              OpenStruct.new({
                opened_issues: sum_objects(COUNT, OPENED_ISSUE_STATE, ISSUE_TYPE),
                closed_issues: sum_objects(COUNT, CLOSED_ISSUE_STATE, ISSUE_TYPE),
                opened_epics: sum_objects(COUNT, OPENED_EPIC_STATE, EPIC_TYPE),
                closed_epics: sum_objects(COUNT, CLOSED_EPIC_STATE, EPIC_TYPE)
              })
            end
          end

          def aggregate_weight_sum(tree)
            strong_memoize(:weight_sum_aggregate) do
              calculate_recursive_sums(WEIGHT_SUM, tree)
              OpenStruct.new({
                opened_issues: sum_objects(WEIGHT_SUM, OPENED_ISSUE_STATE, ISSUE_TYPE),
                closed_issues: sum_objects(WEIGHT_SUM, CLOSED_ISSUE_STATE, ISSUE_TYPE)
              })
            end
          end

          def direct_totals(facet)
            # Sums of only child issues and immediate child epics (but not their issues
            # )
            strong_memoize(:"direct_#{facet}_totals") do
              []
            end
          end

          def calculated_totals(facet)
            if facet == COUNT
              return calculated_count_totals
            end

            calculated_weight_sum_totals
          end

          def calculate_recursive_sums(facet, tree)
            return calculated_totals(facet) if calculated_totals(facet)

            sum_total = []
            children.each do |child|
              child_sums = child.calculate_recursive_sums(facet, tree)
              sum_total.concat(child_sums)
            end
            sum_total.concat(direct_totals(facet))
            set_calculated_total(facet, sum_total)
          end

          def inspect
            {
                epic_id: @epic_id,
                parent_id: @parent_id,
                direct_count_totals: direct_count_totals,
                direct_weight_sum_totals: direct_weight_sum_totals,
                children: children,
                object_id: object_id
            }.to_json
          end

          alias_method :to_s, :inspect

          private

          def sum_objects(facet, state, type)
            sums = calculated_totals(facet) || []
            return 0 if sums.empty?

            sums.inject(0) do |result, sum|
              result += sum.value if sum.state == state && sum.type == type
              result
            end
          end

          def create_sum_if_needed(facet, state, type, value)
            return if value.nil? || value < 1

            direct_totals(facet) << Sum.new(facet, state, type, value)
          end

          def set_epic_attributes(record)
            @epic_state_id = record[:epic_state_id]
            @parent_id = record[:parent_id]
          end

          def set_calculated_total(facet, calculated_sums)
            if facet == COUNT
              @calculated_count_totals = calculated_sums
            else
              @calculated_weight_sum_totals = calculated_sums
            end
          end

          Sum = Struct.new(:facet, :state, :type, :value) do
            def inspect
              "<Sum facet=#{facet}, state=#{state}, type=#{type}, value=#{value}>"
            end
          end
        end
      end
    end
  end
end
