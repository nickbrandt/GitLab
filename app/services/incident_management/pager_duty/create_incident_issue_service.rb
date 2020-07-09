# frozen_string_literal: true

module IncidentManagement
  module PagerDuty
    class CreateIncidentIssueService < BaseService
      def initialize(project, incident_payload)
        super(project, User.alert_bot, incident_payload)
      end

      def execute
        return forbidden unless webhook_available?

        issue = create_issue
        return error(issue.errors.full_messages.to_sentence, issue) unless issue.valid?

        success(issue)
      end

      private

      alias_method :incident_payload, :params

      def create_issue
        label_result = find_or_create_incident_label

        # Create an unlabelled issue if we couldn't create the label
        # due to a race condition.
        # See https://gitlab.com/gitlab-org/gitlab-foss/issues/65042
        extra_params = label_result.success? ? { label_ids: [label_result.payload[:label].id] } : {}

        Issues::CreateService.new(
          project,
          current_user,
          title: issue_title,
          description: issue_description,
          **extra_params
        ).execute
      end

      def webhook_available?
        Feature.enabled?(:pagerduty_webhook, project)
      end

      def forbidden
        ServiceResponse.error(message: 'Forbidden', http_status: :forbidden)
      end

      def find_or_create_incident_label
        ::IncidentManagement::CreateIncidentLabelService.new(project, current_user).execute
      end

      def issue_title
        incident_payload['title']
      end

      def issue_description
        markdown_line_break = '  '

        <<~MARKDOWN.chomp
          **Incident:** #{markdown_incident}#{markdown_line_break}
          **Incident number:** #{incident_payload['incident_number']}#{markdown_line_break}
          **Urgency:** #{incident_payload['urgency']}#{markdown_line_break}
          **Status:** #{incident_payload['status']}#{markdown_line_break}
          **Incident key:** #{incident_payload['incident_key']}#{markdown_line_break}
          **Created at:** #{markdown_incident_created_at}#{markdown_line_break}
          **Assignees:** #{markdown_assignees.join(', ')}#{markdown_line_break}
          **Impacted services:** #{markdown_impacted_services.join(', ')}
        MARKDOWN
      end

      def markdown_incident
        "[#{incident_payload['title']}](#{incident_payload['url']})"
      end

      def incident_created_at
        Time.parse(incident_payload['created_at'])
      rescue
        Time.current
      end

      def markdown_incident_created_at
        incident_created_at.strftime('%d %B %Y, %-l:%M%p (%Z)')
      end

      def markdown_assignees
        Array(incident_payload['assignees']).map do |assignee|
          "[#{assignee['summary']}](#{assignee['url']})"
        end
      end

      def markdown_impacted_services
        Array(incident_payload['impacted_services']).map do |is|
          "[#{is['summary']}](#{is['url']})"
        end
      end

      def success(issue)
        ServiceResponse.success(payload: { issue: issue })
      end

      def error(message, issue = nil)
        ServiceResponse.error(payload: { issue: issue }, message: message)
      end
    end
  end
end
