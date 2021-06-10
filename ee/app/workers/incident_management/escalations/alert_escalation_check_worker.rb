# frozen_string_literal: true

module IncidentManagement
  module Escalations
    class AlertEscalationCheckWorker
      include ApplicationWorker

      urgency :high

      idempotent!
      feature_category :incident_management

      def initialize(escalation_id)
        @escalation_id = escalation_id
      end

      def perform
        escalation = IncidentManagement::AlertEscalation.find_by_id(escalation_id)

        IncidentManagement::Escalations::ProcessService.new(escalation).execute
      end

      private

      attr_reader :escalation_id
    end
  end
end
