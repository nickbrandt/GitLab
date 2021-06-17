# frozen_string_literal: true

module EE
  module AlertManagement
    module AlertProcessing
      extend ::Gitlab::Utils::Override

      private

      override :process_new_alert
      def process_new_alert
        super

        create_escalation
      end

      override :complete_post_processing_tasks
      def complete_post_processing_tasks
        super

        notify_oncall if oncall_notification_recipients.present? && notifying_alert?
      end

      def notify_oncall
        notification_service
          .async
          .notify_oncall_users_of_alert(oncall_notification_recipients.to_a, alert)
      end

      def oncall_notification_recipients
        strong_memoize(:oncall_notification_recipients) do
          ::IncidentManagement::OncallUsersFinder.new(project).execute
        end
      end

      def create_escalation
        ::IncidentManagement::Escalations::CreateService.new(alert).execute
      end
    end
  end
end
