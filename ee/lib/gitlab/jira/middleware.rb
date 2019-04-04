# frozen_string_literal: true

module Gitlab
  module Jira
    class Middleware
      def self.jira_dvcs_connector?(env)
        env['HTTP_USER_AGENT']&.downcase&.start_with?('jira dvcs connector')
      end

      def initialize(app)
        @app = app
      end

      def call(env)
        env['HTTP_AUTHORIZATION']&.sub!('token', 'Bearer') if self.class.jira_dvcs_connector?(env)

        @app.call(env)
      end
    end
  end
end
