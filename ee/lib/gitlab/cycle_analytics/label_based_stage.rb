# frozen_string_literal: true

class Gitlab::CycleAnalytics::LabelBasedStage
  attr_reader :label

  def initialize(label:)
    @label = label
  end

  def median_in_days(&block)
    query = resource_label_event_table
      .project(seconds_between_label_addition_and_removal)
      .where(resource_label_event_table[:label_id].eq(label.id))
      .group(resource_label_event_table[:issue_id])

    query = yield(resource_label_event_table, query) if block_given?
    median_in_seconds = execute_query(median_query_with_cte_table(query)).first["median_in_seconds"]

    return unless median_in_seconds

    median_in_seconds.fdiv(1.day.to_i).round
  end

  def resource_label_event_table
    @resource_label_event_table ||= ResourceLabelEvent.arel_table
  end

  def label_removed_at_in_seconds
    sum_epoch_seconds_by_action(ResourceLabelEvent.actions[:remove])
  end

  def label_added_at_in_seconds
    sum_epoch_seconds_by_action(ResourceLabelEvent.actions[:add])
  end

  def label_removed_at_in_seconds_with_null_check
    Arel::Nodes::Addition.new(
      Arel::Nodes::NamedFunction.new('COALESCE', [
        label_removed_at_in_seconds,
        Arel.sql('0')
      ]),
      Arel.sql(current_epoch_seconds)
    )
  end

  def sum_epoch_seconds_by_action(action)
    Arel::Nodes::InfixOperation.new(
      '',
      Arel::Nodes::NamedFunction.new('SUM', [
        Arel::Nodes::NamedFunction.new('EXTRACT', [
          Arel::Nodes::NamedFunction.new('EPOCH FROM ', [
            resource_label_event_table[:created_at]
          ])
        ])
      ]),
      Arel::Nodes::NamedFunction.new('FILTER', [
        Arel::Nodes::InfixOperation.new(
          '',
          Arel.sql('WHERE'),
          resource_label_event_table[:action].eq(action)
        )
      ])
    )
  end

  def seconds_between_label_addition_and_removal
    Arel::Nodes::Case.new
      .when(
        Arel::Nodes::NamedFunction.new('MOD', [
          Arel::Nodes::NamedFunction.new('COUNT', [Arel.sql('*')]),
          Arel.sql('2')
        ]).eq(0),
        Arel::Nodes::Subtraction.new(
          label_removed_at_in_seconds,
          label_added_at_in_seconds
        )
      ).else(
        Arel::Nodes::Subtraction.new(
          label_removed_at_in_seconds_with_null_check,
          label_added_at_in_seconds
        )).as('duration')
  end

  def median_query_with_cte_table(query)
    cte_table = Arel::Table.new("cte_table_for_label_based_stage_duration")
    as_query = Arel::Nodes::As.new(cte_table, query)

    percentile_disc_ordering = Arel::Nodes::UnaryOperation.new(
      Arel::Nodes::SqlLiteral.new('ORDER BY'),
      cte_table[:duration]
    )
    percentile_disc = Arel::Nodes::NamedFunction.new(
      'percentile_disc(0.5) WITHIN GROUP',
      [percentile_disc_ordering]
    )
    cte_table.project(percentile_disc.as('median_in_seconds')).with(as_query)
  end

  def execute_query(query)
    ActiveRecord::Base.connection.execute(query.to_sql)
  end

  def current_epoch_seconds
    Time.now.to_i.to_s
  end
end
