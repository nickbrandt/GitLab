# frozen_string_literal: true

module VulnerabilitiesHelper
  def vulnerability_data(vulnerability, pipeline)
    return unless vulnerability

    {
      create_issue_url: create_vulnerability_feedback_issue_path(vulnerability.finding.project),
      id: vulnerability.id,
      description: vulnerability.finding.description,
      severity: vulnerability.severity,
      confidence: vulnerability.confidence,
      category: vulnerability.report_type,
      state: vulnerability.state,
      title: vulnerability.title,
      solution: vulnerability.finding.solution,
      identifiers: vulnerability.finding.indentifiers,
      links: vulnerability.finding.links,
      remediations: vulnerability.finding.remediations,
      issue_feedback: vulnerability.finding.issue_feedback,
      location: vulnerability.finding.location,
      project_fingerprint: vulnerability.finding.project_fingerprint
      create_mr_url: create_vulnerability_feedback_merge_request_path(vulnerability.finding.project),
    }
  end

  def vulnerability_pipeline_data(pipeline)
    return unless pipeline

    {
      id: pipeline.id,
      created_at: pipeline.created_at.iso8601,
      url: pipeline_path(pipeline),
      source_branch: pipeline.ref
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
      :merge_request_feedback,
      :project,
      :remediations
    ).merge(
      solution: remediation ? remediation['summary'] : occurrence[:solution]
    )
  end

  def vulnerability_file_link(vulnerability)
    finding = vulnerability.finding
    location = finding.location
    branch = finding.pipelines&.last&.sha || vulnerability.project.default_branch
    link_text = location['file']
    link_path = project_blob_path(vulnerability.project, tree_join(branch, location['file']))

    if location['start_line']
      link_text += ":#{location['start_line']}"
      link_path += "#L#{location['start_line']}"
    end

    link_to link_text, link_path, target: '_blank', rel: 'noopener noreferrer'
  end
end
