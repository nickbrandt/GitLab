# frozen_string_literal: true

module Ci
  class FreezePeriodStatus
  attr_reader :project

  def initialize(project_id:)
    @project = Project.find(project_id)
  end

  def execute
    project.freeze_periods.any? { |period| within_freeze_period?(period) }
  end

  def within_freeze_period?(period)
    # previous_freeze_end, ..., previous_freeze_start, ..., NOW, ..., next_freeze_end, ..., next_freeze_start
    # Current time is within a freeze period if
    # it falls between a previous freeze start and next freeze end
    previous_freeze_start = previous_time(period.freeze_start, period.cron_timezone)
    previous_freeze_end = previous_time(period.freeze_end, period.cron_timezone)
    next_freeze_start = next_time(period.freeze_start, period.cron_timezone)
    next_freeze_end = next_time(period.freeze_end, period.cron_timezone)

    previous_freeze_end < previous_freeze_start &&
      previous_freeze_start <= time_zone_now &&
      time_zone_now <= next_freeze_end &&
      next_freeze_end < next_freeze_start
  end

  private

  def next_time(cron, cron_timezone)
    Gitlab::Ci::CronParser.new(cron, cron_timezone).next_time_from(time_zone_now)
  end

  def previous_time(cron, cron_timezone)
    Gitlab::Ci::CronParser.new(cron, cron_timezone).previous_time_from(time_zone_now)
  end

  def time_zone_now
    @time_zone_now ||= Time.zone.now
  end
end
