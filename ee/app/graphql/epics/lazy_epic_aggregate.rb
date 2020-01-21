# frozen_string_literal: true

module Epics
  class LazyEpicAggregate
    include AggregateConstants

    attr_reader :facet, :epic_id, :lazy_state

    # Because facets "count" and "weight_sum" share the same db query, but have a different graphql type object,
    # we can separate them and serve only the fields which are requested by the GraphQL query
    def initialize(query_ctx, epic_id, aggregate_facet)
      @epic_id = epic_id

      raise ArgumentError.new("No aggregate facet provided. Please specify either #{COUNT} or #{WEIGHT_SUM}") unless aggregate_facet.present?
      raise ArgumentError.new("Invalid aggregate facet #{aggregate_facet} provided. Please specify either #{COUNT} or #{WEIGHT_SUM}") unless [COUNT, WEIGHT_SUM].include?(aggregate_facet.to_sym)

      @facet = aggregate_facet.to_sym

      # Initialize the loading state for this query,
      # or get the previously-initiated state
      @lazy_state = query_ctx[:lazy_epic_aggregate] ||= {
          pending_ids: Set.new,
          tree: {}
      }
      # Register this ID to be loaded later:
      @lazy_state[:pending_ids] << epic_id
    end

    # Return the loaded record, hitting the database if needed
    def epic_aggregate
      # Check if the record was already loaded:
      # load from tree by epic
      loaded_epic_info_node = @lazy_state[:tree][@epic_id]

      if loaded_epic_info_node
        # The pending IDs were already loaded,
        # so return the result of that previous load
        loaded_epic_info_node.aggregate_object_by(@facet)
      else
        load_records_into_tree
      end
    end

    private

    def tree
      @lazy_state[:tree]
    end

    def load_records_into_tree
      # The record hasn't been loaded yet, so
      # hit the database with all pending IDs
      pending_ids = @lazy_state[:pending_ids].to_a

      # Fire off the db query and get the results (grouped by epic_id and facet)
      raw_epic_aggregates = Epics::BulkEpicAggregateLoader.new(epic_ids: pending_ids).execute

      # Assemble the tree and sum everything
      create_structure_from(raw_epic_aggregates)

      @lazy_state[:pending_ids].clear

      # Now, get the matching node and return its aggregate depending on the facet:
      epic_node = @lazy_state[:tree][@epic_id]
      epic_node.aggregate_object_by(@facet)
    end

    def create_structure_from(aggregate_records)
      # create EpicNode object for each epic id
      aggregate_records.each do |epic_id, aggregates|
        next if aggregates.nil? || aggregates.empty?

        new_node = EpicNode.new(epic_id, aggregates)
        tree[epic_id] = new_node
      end

      associate_parents_and_children
      assemble_direct_sums
      calculate_recursive_sums
    end

    # each of the methods below are done one after the other
    def associate_parents_and_children
      tree.each do |epic_id, node|
        node.child_ids = tree.select { |_, child_node| epic_id == child_node.parent_id }.keys
      end
    end

    def assemble_direct_sums
      tree.each do |_, node|
        node.assemble_issue_sums

        node_children = tree.select { |_, child_node| node.epic_id == child_node.parent_id }.values
        node.assemble_epic_sums(node_children)
      end
    end

    def calculate_recursive_sums
      tree.each do |_, node|
        node.calculate_recursive_sums(tree)
      end
    end
  end
end
