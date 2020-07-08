# frozen_string_literal: true

module Projects
  module Integrations
    module Jira
      class IssuesController < Projects::ApplicationController
        include RecordUserLastActivity

        before_action :check_feature_enabled!

        before_action do
          push_frontend_feature_flag(:jira_integration, project)
          push_frontend_feature_flag(:vue_issuables_list, project)
        end

        def index
          respond_to do |format|
            format.html
            format.json do
              render json: issues_json
            rescue Projects::Integrations::Jira::IntegrationError, Projects::Integrations::Jira::RequestError => e
              render_bad_request(e)
            end
          end
        end

        private

        def issues_json
          jira_issues = ::Projects::Integrations::Jira::IssuesFinder.new(project, {}).execute

          ::Integrations::Jira::IssueSerializer.new.represent(jira_issues, project: project)
        end

        protected

        def check_feature_enabled!
          return render_404 unless Feature.enabled?(:jira_integration, project)
        end

        def render_bad_request(error)
          render json: { errors: [error.message] }, status: :bad_request
        end
      end
    end
  end
end
