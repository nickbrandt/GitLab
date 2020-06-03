# frozen_string_literal: true

module Gitlab
  module AlertManagement
    module IncomingEmail
      # Handles alert creation emails supporting the following format:
      #   gitlab-incoming+gitlab-org-gitlab-20-abcdef01-alert@incoming.gitlab.com
      class CreateAlertHandler < ::Gitlab::Email::Handler::BaseHandler
        include Gitlab::Utils::StrongMemoize
        include Gitlab::Email::Handler::ReplyProcessing

        HANDLER_REGEX = /\A#{HANDLER_ACTION_BASE_REGEX}-(?<short_token>\h{#{SHORT_TOKEN_LENGTH}})-alert\z/.freeze
        InvalidToken = Class.new(Gitlab::Email::UserNotAuthorizedError)

        def initialize(mail, mail_key)
          super

          if matched = HANDLER_REGEX.match(mail_key)
            @project = find_project(matched[:project_slug], matched[:project_id])
            @short_token = matched[:short_token]
          end
        end

        def can_handle?
          project && short_token
        end

        def execute
          raise ProjectNotFound unless project
          # TODO Add new FeatureNotAvailable, raise it here and handle in EmailReceiverWorker
          return unless feature_available?
          raise InvalidToken unless short_token_valid?

          response = process_alert

          raise InvalidRecordError, response.message if response.error?
        end

        def metrics_event
          :receive_email_create_alert
        end

        private

        attr_reader :project, :short_token

        def find_project(project_slug, project_id)
          strong_memoize(:project) do
            project = Project.find_by_id(project_id)
            validate_slug(project_slug, project)
          end
        end

        def validate_slug(project_slug, project)
          project if project_slug == project&.full_path_slug
        end

        def feature_available?
          AlertManagement::IncomingEmail.enabled?(project)
        end

        def short_token_valid?
          short_token == AlertManagement::IncomingEmail.short_token(project)
        end

        def process_alert
          token = AlertManagement::IncomingEmail.token(project)
          alert_payload = {
            'title' => mail.subject,
            'description' => message
          }

          ::Projects::Alerting::NotifyService
            .new(project, author, alert_payload)
            .execute(token)
        end

        def author
          User.alert_bot
        end
      end
    end
  end
end
