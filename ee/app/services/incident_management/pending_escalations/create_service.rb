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
        escalation_ids = rules.map do |rule|
          escalaton = create_escalation(rule)
          escalaton.id
        end

        process_escalations(escalation_ids)
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

      def process_escalations(escalation_ids)
        args = escalation_ids.map { |id| [id] }

        ::IncidentManagement::PendingEscalations::AlertCheckWorker.bulk_perform_async(args) # rubocop:disable Scalability/BulkPerformWithContext
      end
    end
  end
end
