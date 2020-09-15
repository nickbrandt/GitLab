# frozen_string_literal: true

module IncidentManagement
  module Incidents
    class UpdateSeverityService < BaseService
      def initialize(issuable, current_user, severity)
        super(issuable.project, current_user)

        @issuable = issuable
        @severity = severity.to_s.downcase
        @severity = IssuableSeverity::DEFAULT unless IssuableSeverity.severities.key?(@severity)
      end

      def execute
        return unless issuable.incident?

        issuable_severity.update(severity: severity)
      end

      private

      attr_reader :issuable, :severity

      def issuable_severity
        issuable.issuable_severity || issuable.build_issuable_severity(issue_id: issuable.id)
      end
    end
  end
end
