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
        end

        protected

        def check_feature_enabled!
          return render_404 unless Feature.enabled?(:jira_integration, project)
        end
      end
    end
  end
end
