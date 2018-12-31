# frozen_string_literal: true

# handles service desk issue creation emails with these formats:
#   incoming+gitlab-org-gitlab-ce-20-issue-@incoming.gitlab.com
#   incoming+gitlab-org/gitlab-ce@incoming.gitlab.com (legacy)
module Gitlab
  module Email
    module Handler
      module EE
        class ServiceDeskHandler < BaseHandler
          include ReplyProcessing

          HANDLER_REGEX        = /\A#{::Gitlab::Email::Handler::BaseHandler::HANDLER_ACTION_BASE_REGEX}-issue-\z/.freeze
          HANDLER_REGEX_LEGACY = /\A(?<project_path>[^\+]*)\z/.freeze

          def initialize(mail, mail_key)
            super(mail, mail_key)

            if !mail_key&.include?('/') && (matched = HANDLER_REGEX.match(mail_key.to_s))
              @project_slug = matched[:project_slug]
              @project_id   = matched[:project_id]&.to_i
            elsif matched = HANDLER_REGEX_LEGACY.match(mail_key.to_s)
              @project_path = matched[:project_path]
            end
          end

          def can_handle?
            ::EE::Gitlab::ServiceDesk.enabled? && (project_id || can_handle_legacy_format?)
          end

          def execute
            raise ProjectNotFound if project.nil?

            create_issue!
            send_thank_you_email! if from_address
          end

          def metrics_params
            super.merge(project: project&.full_path)
          end

          private

          attr_reader :project_id, :project_path

          def project
            super

            @project = nil unless @project&.service_desk_enabled?
            @project
          end

          def create_issue!
            # NB: the support bot is specifically forbidden
            # from mentioning any entities, or from using
            # slash commands.
            @issue = Issues::CreateService.new(
              project,
              User.support_bot,
              title: issue_title,
              description: message,
              confidential: true,
              service_desk_reply_to: from_address
            ).execute

            raise InvalidIssueError unless @issue.persisted?
          end

          def send_thank_you_email!
            Notify.service_desk_thank_you_email(@issue.id).deliver_later!
          end

          def from_address
            (mail.reply_to || []).first || mail.from.first || mail.sender
          end

          def issue_title
            from = "(from #{from_address})" if from_address

            "Service Desk #{from}: #{mail.subject}"
          end

          def can_handle_legacy_format?
            project_path && project_path.include?('/') && !mail_key.include?('+')
          end
        end
      end
    end
  end
end
