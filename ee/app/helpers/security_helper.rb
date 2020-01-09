# frozen_string_literal: true

module SecurityHelper
  def instance_security_dashboard_data
    {
      dashboard_documentation: help_page_path('user/application_security/security_dashboard/index', anchor: 'instance-security-dashboard'),
      empty_dashboard_state_svg_path: image_path('illustrations/security-dashboard-empty-state.svg'),
      empty_state_svg_path: image_path('illustrations/operations-dashboard_empty.svg'),
      project_add_endpoint: security_projects_path,
      project_list_endpoint: security_projects_path,
      vulnerabilities_count_endpoint: summary_security_vulnerability_findings_path,
      vulnerabilities_endpoint: security_vulnerability_findings_path,
      vulnerabilities_history_endpoint: history_security_vulnerability_findings_path,
      vulnerability_feedback_help_path: help_page_path('user/application_security/index', anchor: 'interacting-with-the-vulnerabilities')
    }
  end
end
