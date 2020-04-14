# frozen_string_literal: true

module VulnerabilitiesHelper
  def vulnerability_data(vulnerability, pipeline)
    return unless vulnerability

    {
      vulnerability_json: VulnerabilitySerializer.new.represent(vulnerability).to_json,
      project_fingerprint: vulnerability.finding.project_fingerprint,
      create_issue_url: create_vulnerability_feedback_issue_path(vulnerability.finding.project),
      notes_url: project_security_vulnerability_notes_path(vulnerability.project, vulnerability),
      discussions_url: discussions_project_security_vulnerability_path(vulnerability.project, vulnerability),
      pipeline_json: vulnerability_pipeline_data(pipeline).to_json,
      has_mr: !!vulnerability.finding.merge_request_feedback.try(:merge_request_iid),
      vulnerability_feedback_help_path: help_page_path('user/application_security/index', anchor: 'interacting-with-the-vulnerabilities'),
      finding_json: vulnerability_finding_data(vulnerability.finding).to_json,
      timestamp: Time.now.to_i
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

  def vulnerability_finding_data(finding)
    occurrence = Vulnerabilities::OccurrenceSerializer.new(current_user: current_user).represent(finding)
    remediation = occurrence[:remediations]&.first

    occurrence.slice(
      :description,
      :identifiers,
      :links,
      :location,
      :name,
      :issue_feedback,
      :project
    ).merge(
      solution: remediation ? remediation['summary'] : occurrence[:solution]
    )
  end

  def vulnerability_file_link(vulnerability)
    finding = vulnerability.finding
    location = finding.location
    branch = finding.pipelines&.last&.sha || vulnerability.project.default_branch
    link_text = "#{location['file']}:#{location['start_line']}"
    offset = location['start_line'] ? "#L#{location['start_line']}" : ''
    link_path = project_blob_path(vulnerability.project, tree_join(branch, location['file'])) + offset

    link_to link_text, link_path, target: '_blank', rel: 'noopener noreferrer'
  end
end
