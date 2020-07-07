# frozen_string_literal: true

module Vulnerabilities
  class UpdateService
    include Gitlab::Allowable

    attr_reader :project, :author, :finding

    delegate :vulnerability, to: :finding

    def initialize(project, author, finding:)
      @project = project
      @author = author
      @finding = finding
    end

    def execute
      raise Gitlab::Access::AccessDeniedError unless can?(author, :create_vulnerability, project)

      vulnerability.update!(vulnerability_params)
      Statistics::UpdateService.update_for(vulnerability)

      vulnerability
    end

    private

    def vulnerability_params
      {
        title: finding.name,
        severity: vulnerability.severity_overridden? ? vulnerability.severity : finding.severity,
        confidence: vulnerability.confidence_overridden? ? vulnerability.confidence : finding.confidence
      }
    end
  end
end
