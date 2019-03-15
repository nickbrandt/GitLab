# frozen_string_literal: true

module IncidentManagement
  class ProjectIncidentManagementSetting < ApplicationRecord
    belongs_to :project

    validate :issue_template_exists, if: :create_issue?

    def available_issue_templates
      Gitlab::Template::IssueTemplate.all(project)
    end

    private

    def issue_template_exists
      return unless issue_template_key.present?

      Gitlab::Template::IssueTemplate.find(issue_template_key, project)
    rescue Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError
      errors.add(:issue_template_key, 'not found')
    end
  end
end
