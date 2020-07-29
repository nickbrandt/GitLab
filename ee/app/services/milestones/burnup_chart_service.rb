# frozen_string_literal: true

# This service computes the milestone's daily total number of issues and their weights.
# For each day, this returns the totals for all issues that are assigned to the milestone at that point in time.
# This represents the scope for this milestone. This also returns separate totals for closed issues which represent the completed work.
#
# This is implemented by iterating over all relevant resource events ordered by time. We need to do this
# so that we can keep track of the issue's state during that point in time and handle the events based on that.

class Milestones::BurnupChartService
  include Gitlab::Utils::StrongMemoize

  EVENT_COUNT_LIMIT = 50_000

  TooManyEventsError = Class.new(StandardError)

  def initialize(milestone)
    raise ArgumentError, 'Milestone must have a start and due date' if milestone.start_date.blank? || milestone.due_date.blank?

    @milestone = milestone
  end

  def execute
    @issue_states = {}
    @chart_data = []

    raise TooManyEventsError if resource_events.num_tuples > EVENT_COUNT_LIMIT

    resource_events.each do |event|
      case event['event_type']
      when 'milestone'
        handle_milestone_event(event)
      when 'state'
        handle_state_event(event)
      when 'weight'
        handle_weight_event(event)
      end
    end

    chart_data
  end

  private

  attr_reader :milestone, :issue_states, :chart_data

  def handle_milestone_event(event)
    issue_state = find_issue_state(event['issue_id'])

    return if issue_state[:milestone] == milestone.id && event['action'] == ResourceMilestoneEvent.actions[:add] && event['value'] == milestone.id

    if event['action'] == ResourceMilestoneEvent.actions[:add] && event['value'] == milestone.id
      handle_add_milestone_event(event)
    elsif issue_state[:milestone] == milestone.id
      # If the issue is currently assigned to the milestone, then treat any event here as a removal.
      # We do not have a separate `:remove` event when replacing milestones with another one.
      handle_remove_milestone_event(event)
    end

    issue_state[:milestone] = event['value']
  end

  def handle_add_milestone_event(event)
    issue_state = find_issue_state(event['issue_id'])

    increment_scope(event['created_at'], issue_state[:weight])

    if issue_state[:state] == ResourceStateEvent.states[:closed]
      increment_completed(event['created_at'], issue_state[:weight])
    end
  end

  def handle_remove_milestone_event(event)
    issue_state = find_issue_state(event['issue_id'])

    decrement_scope(event['created_at'], issue_state[:weight])

    if issue_state[:state] == ResourceStateEvent.states[:closed]
      decrement_completed(event['created_at'], issue_state[:weight])
    end
  end

  def handle_state_event(event)
    issue_state = find_issue_state(event['issue_id'])
    old_state = issue_state[:state]
    issue_state[:state] = event['value']

    return if issue_state[:milestone] != milestone.id

    if old_state == ResourceStateEvent.states[:closed] && event['value'] == ResourceStateEvent.states[:reopened]
      decrement_completed(event['created_at'], issue_state[:weight])
    elsif ResourceStateEvent.states.values_at(:opened, :reopened).include?(old_state) && event['value'] == ResourceStateEvent.states[:closed]
      increment_completed(event['created_at'], issue_state[:weight])
    end
  end

  def handle_weight_event(event)
    issue_state = find_issue_state(event['issue_id'])
    old_weight = issue_state[:weight]
    issue_state[:weight] = event['value'] || 0

    return if issue_state[:milestone] != milestone.id

    add_chart_data(event['created_at'], :scope_weight, issue_state[:weight] - old_weight)

    if issue_state[:state] == ResourceStateEvent.states[:closed]
      add_chart_data(event['created_at'], :completed_weight, issue_state[:weight] - old_weight)
    end
  end

  def increment_scope(timestamp, weight)
    add_chart_data(timestamp, :scope_count, 1)
    add_chart_data(timestamp, :scope_weight, weight)
  end

  def decrement_scope(timestamp, weight)
    add_chart_data(timestamp, :scope_count, -1)
    add_chart_data(timestamp, :scope_weight, -weight)
  end

  def increment_completed(timestamp, weight)
    add_chart_data(timestamp, :completed_count, 1)
    add_chart_data(timestamp, :completed_weight, weight)
  end

  def decrement_completed(timestamp, weight)
    add_chart_data(timestamp, :completed_count, -1)
    add_chart_data(timestamp, :completed_weight, -weight)
  end

  def add_chart_data(timestamp, field, value)
    date = timestamp.to_date
    date = milestone.start_date if date < milestone.start_date

    if chart_data.empty?
      chart_data.push({
        date: date,
        scope_count: 0,
        scope_weight: 0,
        completed_count: 0,
        completed_weight: 0
      })
    elsif chart_data.last[:date] != date
      # To start a new day entry we copy the previous day's data because the numbers are cumulative
      chart_data.push(
        chart_data.last.merge(date: date)
      )
    end

    chart_data.last[field] += value
  end

  def find_issue_state(issue_id)
    issue_states[issue_id] ||= {
      milestone: nil,
      weight: 0,
      state: ResourceStateEvent.states[:opened]
    }
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def resource_events
    strong_memoize(:resource_events) do
      union = Gitlab::SQL::Union.new([milestone_events, state_events, weight_events]) # rubocop: disable Gitlab/Union

      ActiveRecord::Base.connection.execute("(#{union.to_sql}) ORDER BY created_at LIMIT #{EVENT_COUNT_LIMIT + 1}")
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def milestone_events
    ResourceMilestoneEvent.by_issue_ids_and_created_at_earlier_or_equal_to(issue_ids, end_time)
      .select('\'milestone\' AS event_type, created_at, milestone_id AS value, action, issue_id')
  end

  def state_events
    ResourceStateEvent.by_issue_ids_and_created_at_earlier_or_equal_to(issue_ids, end_time)
      .select('\'state\' AS event_type, created_at, state AS value, NULL AS action, issue_id')
  end

  def weight_events
    ResourceWeightEvent.by_issue_ids_and_created_at_earlier_or_equal_to(issue_ids, end_time)
      .select('\'weight\' AS event_type, created_at, weight AS value, NULL AS action, issue_id')
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def issue_ids
    # We find all issues that have this milestone added before this milestone's due date.
    # We cannot just filter by `issues.milestone_id` because there might be issues that have
    # since been moved to other milestones and we still need to include these in this graph.
    ResourceMilestoneEvent
      .select(:issue_id)
      .where({
        milestone_id: milestone.id,
        action: :add
      })
      .where('created_at <= ?', end_time)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def end_time
    @end_time ||= milestone.due_date.end_of_day
  end
end
