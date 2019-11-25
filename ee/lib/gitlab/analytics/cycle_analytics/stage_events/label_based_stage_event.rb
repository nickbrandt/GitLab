# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        # Represents an event that is related to label creation or removal, this model requires a label provided by the user
        class LabelBasedStageEvent < StageEvent
          include ActiveRecord::ConnectionAdapters::Quoting

          def label
            params.fetch(:label)
          end

          def label_id
            label.id
          end

          def self.label_based?
            true
          end

          def timestamp_projection
            Arel.sql("#{join_expression_name}.created_at")
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def apply_query_customization(query)
            query
              .joins("INNER JOIN (#{subquery.to_sql}) #{join_expression_name} on #{join_expression_name}.model_id = #{quote_table_name(object_type.table_name)}.id")
              .where("#{join_expression_name}.label_assignment_order = 1")
          end
          # rubocop: enable CodeReuse/ActiveRecord

          private

          def resource_label_events_table
            ResourceLabelEvent.arel_table
          end

          # Labels can be assigned and unassigned multiple times, we need a way to pick only one record from `resource_label_events` table.
          # Consider the following example:
          #
          # | id | action | label_id | issue_id | created_at |
          # | -- | ------ | -------- | -------- | ---------- |
          # | 1  | add    | 1        | 10       | 2010-01-01 |
          # | 2  | remove | 1        | 10       | 2010-02-01 |
          # | 3  | add    | 1        | 10       | 2015-01-01 |
          # | 4  | remove | 1        | 10       | 2015-02-01 |
          #
          # In this example a label (id: 1) has been assigned and unassigned twice on the same Issue.
          #
          # - IssueLabelAdded event: find the first assignment (add, id = 1)
          # - IssueLabelRemoved event: find the latest unassignment (remove, id = 4)
          #
          # This can be achieved with the PARTITION window function.
          #
          #  - IssueLabelAdded: order by `created_at` ASC and take the row number 1
          #  - IssueLabelRemoved: order by `created_at` DESC and take the row number 1
          #
          #  Arguments:
          #    foreign_key: :issue_id or :merge_request_id (based on resource_label_events table)
          #    label: label model,
          #    action: :add or :remove
          #    order: :asc or :desc

          # rubocop: disable CodeReuse/ActiveRecord
          def resource_label_events_with_subquery(foreign_key, label, action, order)
            ResourceLabelEvent
              .select(:created_at, resource_label_events_table[foreign_key].as('model_id'), partition_select(foreign_key, order).as('label_assignment_order'))
              .where(action: action)
              .where(label_id: label.id)
          end
          # rubocop: enable CodeReuse/ActiveRecord

          # The same join expression could be used multiple times in the same query, to avoid conflicts, we're adding random hex string as suffix.
          def join_expression_name
            @join_expression_name ||= quote_table_name("#{self.class.to_s.demodulize.underscore}_#{SecureRandom.hex(5)}")
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def partition_select(foreign_key, order)
            order_expression = case order
                               when :asc
                                 resource_label_events_table[:created_at].asc
                               when :desc
                                 resource_label_events_table[:created_at].desc
                               else
                                 raise "unsupported order option: #{order}"
                               end

            Arel::Nodes::Over.new(
              Arel::Nodes::NamedFunction.new('row_number', []),
              Arel::Nodes::Window.new.partition(resource_label_events_table[foreign_key]).order(order_expression)
            )
          end
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
