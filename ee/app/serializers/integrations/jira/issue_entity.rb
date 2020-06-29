# frozen_string_literal: true

module Integrations
  module Jira
    class IssueEntity < Grape::Entity
      expose :project_id do |_jira_issue|
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
          {
            name: name,
            color: "#b728d9",
            text_color: "#FFFFFF"
          }
        end
      end

      expose :author do |jira_issue|
        {
          id: 1,
          name: jira_issue.creator['displayName'],
          username: jira_issue.creator['name'],
          avatar_url: 'http://127.0.0.1:3000/uploads/-/system/user/avatar/1/avatar.png',
          web_url: 'http://127.0.0.1:3000/root'
        }
      end

      expose :assignees do |jira_issue|
        [
          {
            id: 1,
            name: jira_issue.assignee&.displayName,
            # username: jira_issue.assignee&.name,
            avatar_url: "http://127.0.0.1:3000/uploads/-/system/user/avatar/1/avatar.png",
            web_url: "http://127.0.0.1:3000/root"
          }
        ]
      end

      expose :weburl do |jira_issue|
        "#{jira_issue.client.options[:site]}projects/#{jira_issue.project.key}/issues/#{jira_issue.key}"
      end

      # TODO
      # {
      #   references: {
      #     short: "#39",
      #     relative: jira_issue.key,
      #     full: "gitlab-org/gitlab-shell#39"
      #   }
      # }

    end
  end
end
