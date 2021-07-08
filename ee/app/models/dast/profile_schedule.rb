# frozen_string_literal: true

class Dast::ProfileSchedule < ApplicationRecord
  include CronSchedulable
  # include Limitable
  include EachBatch

  # self.limit_name = 'ci_pipeline_schedules'
  # self.limit_scope = :project

  self.table_name = 'dast_profile_schedules'

  belongs_to :dast_profile, class_name: 'Dast::Profile', optional: false, inverse_of: :dast_profile_schedules
  belongs_to :owner, class_name: 'User', foreign_key: :user_id

  validates :cron, presence: true
  validates :next_run_at, presence: true

  scope :with_profile_project, -> { includes(dast_profile: [:project, :dast_site_profile, :dast_scanner_profile]) }
  scope :with_owner, -> { includes(:owner) }

  scope :active, -> { where(active: true) }
  # Runnable schedules should be active too.
  scope :runnable_schedules, -> { active.where("next_run_at < ?", Time.zone.now) }

  delegate :project, to: :dast_profile

  private

  def cron_timezone
    next_run_at.zone
  end

  def worker_cron_expression
    Settings.cron_jobs['app_sec_dast_profile_schedule_worker']['cron']
  end
end
