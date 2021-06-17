# frozen_string_literal: true

module IncidentManagement
  module PendingEscalations
    class CreateService < BaseService
      def initialize(target)
        @target = target
        @project = target.project
        @process_time = Time.current
      end

      def execute
        return unless ::Gitlab::IncidentManagement.escalation_policies_available?(project) && !target.resolved?

        policy = escalation_policies.first

        return unless policy

        create_escalations(policy.rules)
      end

      private

      attr_reader :target, :project, :escalation, :process_time

      def escalation_policies
        project.incident_management_escalation_policies.with_rules
      end

      def create_escalations(rules)
        rules.each do |rule|
          escalaton = create_escalation(rule)
          process_escalation(escalaton) if rule.elapsed_time_seconds == 0
        end

      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e, target_type: target.class.to_s, target_id: target.id)
      end

      def create_escalation(rule)
        IncidentManagement::PendingEscalations::Alert.create!(
          target: target,
          rule: rule,
          schedule_id: rule.oncall_schedule_id,
          status: rule.status,
          process_at: rule.elapsed_time_seconds.seconds.after(process_time)
        )
      end

      def process_escalation(escalation)
        ::IncidentManagement::PendingEscalations::ProcessService.new(escalation).execute
      end
    end
  end
end
