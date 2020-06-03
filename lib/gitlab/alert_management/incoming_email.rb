# frozen_string_literal: true

module Gitlab
  module AlertManagement
    module IncomingEmail
      SHORT_TOKEN_LENGTH = 8
      EMAIL_ADDRESS_SUFFIX = 'alert'

      def self.enabled?(project)
        project.alerts_service_activated?
      end

      def self.token(project)
        project.alerts_service&.token if enabled?(project)
      end

      def self.short_token(project)
        token(project)&.first(SHORT_TOKEN_LENGTH)
      end

      # Returns gitlab_incoming+namespace-project-path-1-abcdef012-alert@incoming.gitlab.com
      def self.email_address(project)
        token = short_token(project)
        return unless token

        key = [
          project.full_path_slug,
          project.id,
          token,
          EMAIL_ADDRESS_SUFFIX
        ].join('-')

        Gitlab::IncomingEmail.reply_address(key)
      end
    end
  end
end
