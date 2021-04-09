
# frozen_string_literal: true

module Security
  class OrchestrationPolicyRuleSchedule < ApplicationRecord
    include Gitlab::Utils::StrongMemoize
    include Schedulable

    self.table_name = 'security_orchestration_policy_rule_schedules'

    belongs_to :security_orchestration_policy_configuration, class_name: 'Security::OrchestrationPolicyConfiguration', foreign_key: 'security_orchestration_policy_configuration_id'
    belongs_to :owner, class_name: 'User', foreign_key: 'user_id'

    validates :cron, presence: true
    validates :policy_index, presence: true

    delegate :project, :security_orchestration_policy_project, to: :security_orchestration_policy_configuration

    scope :preloaded, -> { preload(:owner, security_orchestration_policy_configuration: [:security_orchestration_policy_project, :project]) }
    scope :runnable_schedules, -> { where('next_run_at < ?', Time.zone.now) }

    def policy
      strong_memoize(:policy) do
        security_orchestration_policy_configuration.active_policies[policy_index]
      end
    end

    ##
    # The `next_run_at` column is set to the actual execution date of `PipelineScheduleWorker`.
    # This way, a schedule like `*/1 * * * *` won't be triggered in a short interval
    # when PipelineScheduleWorker runs irregularly by Sidekiq Memory Killer.
    def set_next_run_at
      now = Time.zone.now
      ideal_next_run = ideal_next_run_from(now)

      self.next_run_at = if ideal_next_run == cron_worker_next_run_from(now)
                           ideal_next_run
                         else
                           cron_worker_next_run_from(ideal_next_run)
                         end
    end

    private

    def ideal_next_run_from(start_time)
      Gitlab::Ci::CronParser
        .new(cron, Time.zone.name)
        .next_time_from(start_time)
    end

    def cron_worker_next_run_from(start_time)
      Gitlab::Ci::CronParser
        .new(Settings.cron_jobs['security_orchestration_policy_rule_schedule_worker']['cron'], Time.zone.name)
        .next_time_from(start_time)
    end
  end
end
