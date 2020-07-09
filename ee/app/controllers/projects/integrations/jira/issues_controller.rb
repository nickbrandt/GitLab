# frozen_string_literal: true

module Projects
  module Integrations
    module Jira
      class IssuesController < Projects::ApplicationController
        include RecordUserLastActivity
        include SortingHelper
        include SortingPreference

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
          jira_issues = finder.execute
          jira_issues = Kaminari.paginate_array(jira_issues, limit: finder.per_page, total_count: finder.total_count)

          ::Integrations::Jira::IssueSerializer.new
            .with_pagination(request, response)
            .represent(jira_issues, project: project)
        end

        def finder
          @finder ||= finder_type.new(project, finder_options)
        end

        def finder_type
          ::Projects::Integrations::Jira::IssuesFinder
        end

        def finder_options
          params[:state] = default_state if params[:state].blank?
          options = { sort: set_sort_order }

          # Used by view to highlight active option
          @sort = options[:sort]

          params.permit(finder_type.valid_params).merge(options)
        end

        def default_state
          'opened'
        end

        def default_sort_order
          case params[:state]
          when 'opened', 'all' then sort_value_created_date
          when 'closed'        then sort_value_recently_updated
          else sort_value_created_date
          end
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
