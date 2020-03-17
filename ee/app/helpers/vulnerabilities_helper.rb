# frozen_string_literal: true

module VulnerabilitiesHelper
  def vulnerability_data(vulnerability, pipeline)
    return unless vulnerability

    {
      vulnerability_json: vulnerability.to_json,
      project_fingerprint: vulnerability.finding.project_fingerprint,
      create_issue_url: create_vulnerability_feedback_issue_path(vulnerability.finding.project),
      pipeline_json: vulnerability_pipeline_data(pipeline).to_json
    }
  end

  def vulnerability_pipeline_data(pipeline)
    return unless pipeline

    {
      id: pipeline.id,
      created_at: pipeline.created_at.iso8601,
      url: pipeline_path(pipeline)
    }
  end
end
