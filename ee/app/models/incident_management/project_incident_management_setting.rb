# frozen_string_literal: true

module IncidentManagement
  class ProjectIncidentManagementSetting < ApplicationRecord
    belongs_to :project

    validate :issue_template_exists, if: :create_issue?

    after_initialize :set_defaults

    private

    def set_defaults
      self.send_email = true
      self.create_issue = false
    end

    def issue_template_exists
      return unless issue_template_key.present?

      Gitlab::Template::IssueTemplate.find(issue_template_key, project)
    rescue Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError
      errors.add(:issue_template_key, 'not found')
    end
  end
end
