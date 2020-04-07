# frozen_string_literal: true

class Ci::FreezePeriodService
  attr_reader :project

  def initialize(project_id:)
    @project = Project.find(project_id)
  end

  def execute
    frozen = false

    project.project_deploy_freeze_periods.each do |period|
      previous_freeze_start = previous_time(period.freeze_start, period.timezone)
      previous_freeze_end = previous_time(period.freeze_end, period.timezone)
      next_freeze_start = next_time(period.freeze_start, period.timezone)
      next_freeze_end = next_time(period.freeze_end, period.timezone)

      if Time.zone.now >= previous_freeze_start && Time.zone.now <= previous_freeze_end
        frozen = true
      end
      if Time.zone.now >= next_freeze_start && Time.zone.now <= previous_freeze_end
        frozen = true
      end
    end

    frozen
  end

  private

  def next_time(cron, cron_timezone)
    parse_cron(cron, cron_timezone).next_time.utc.in_time_zone(cron_timezone)
  end

  def previous_time(cron, cron_timezone)
    parse_cron(cron, cron_timezone).previous_time.utc.in_time_zone(cron_timezone)
  end

  def parse_cron(cron, cron_timezone)
    Fugit::Cron.parse("#{cron} #{cron_timezone}")
  end
end