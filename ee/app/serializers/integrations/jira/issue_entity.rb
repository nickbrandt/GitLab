# frozen_string_literal: true

module Integrations
  module Jira
    class IssueEntity < Grape::Entity
      expose :project_id do |_jira_issue, options|
        options[:project].id
      end

      expose :title do |jira_issue|
        jira_issue.summary
      end

      expose :created_at do |jira_issue|
        jira_issue.created
      end

      expose :updated_at do |jira_issue|
        jira_issue.updated
      end

      expose :closed_at do |jira_issue|
        jira_issue.resolutiondate
      end

      expose :labels do |jira_issue|
        jira_issue.labels.map do |name|
          bg_color = Label.color_for(name)
          text_color = LabelsHelper.text_color_for_bg(bg_color)

          {
            name: name,
            color: bg_color,
            text_color: text_color

          }
        end
      end

      expose :author do |jira_issue|
        {
          name: jira_issue.reporter.displayName
        }
      end

      expose :assignees do |jira_issue|
        if jira_issue.assignee.present?
          [
            {
              name: jira_issue.assignee.displayName
            }
          ]
        else
          []
        end
      end

      expose :web_url do |jira_issue|
        "#{jira_issue.client.options[:site]}projects/#{jira_issue.project.key}/issues/#{jira_issue.key}"
      end

      expose :references do |jira_issue|
        {
          relative: jira_issue.key
        }
      end

      expose :external_tracker do |_jira_issue|
        'jira'
      end
    end
  end
end
