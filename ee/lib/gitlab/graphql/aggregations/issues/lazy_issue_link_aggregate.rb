# frozen_string_literal: true

module Gitlab
  module Graphql
    module Aggregations
      module Issues
        class LazyIssueLinkAggregate
          attr_reader :issue_id, :lazy_state

          def initialize(query_ctx, issue_id)
            @issue_id = issue_id

            # Initialize the loading state for this query,
            # or get the previously-initiated state
            @lazy_state = query_ctx[:lazy_issue_link_aggregate] ||= {
                pending_ids: Set.new,
                loaded_objects: {}
            }
            # Register this ID to be loaded later:
            @lazy_state[:pending_ids] << issue_id
          end

          # Return the loaded record, hitting the database if needed
          def issue_link_aggregate
            # Check if the record was already loaded:
            # load from loaded_objects by issue
            unless @lazy_state[:loaded_objects][@issue_id]
              load_records_into_loaded_objects
            end

            loaded_objects[@issue_id].any?
          end

          private

          def loaded_objects
            @lazy_state[:loaded_objects]
          end

          def load_records_into_loaded_objects
            # The record hasn't been loaded yet, so
            # hit the database with all pending IDs to prevent N+1
            pending_ids = @lazy_state[:pending_ids].to_a
            blocked = IssueLink.blocked_issues_for_collection(pending_ids).compact.flatten

            pending_ids.each do |id|
              # result is either [] or an array with a link aggregate object
              @lazy_state[:loaded_objects][id] = blocked.select { |o| o.blocked_issue_id == id }
            end

            @lazy_state[:pending_ids].clear
          end
        end
      end
    end
  end
end
