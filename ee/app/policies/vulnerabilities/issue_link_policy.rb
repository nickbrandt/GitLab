# frozen_string_literal: true

module Vulnerabilities
  class IssueLinkPolicy < BasePolicy
    delegate { @subject.vulnerability&.project }

    with_scope :subject
    condition(:cross_project_issue) { @subject.vulnerability&.project != @subject.issue&.project }

    rule { cross_project_issue }.prevent :admin_vulnerability_issue_link
  end
end
