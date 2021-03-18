# frozen_string_literal: true

module Projects
  module Integrations
    module Jira
      class IssuesController < Projects::ApplicationController
        include RecordUserLastActivity
        include SortingHelper
        include SortingPreference
        include RedisTracking

        track_redis_hll_event :index,
          name: 'i_ecosystem_jira_service_list_issues'

        before_action :check_feature_enabled!

        rescue_from ::Projects::Integrations::Jira::IssuesFinder::IntegrationError, with: :render_integration_error
        rescue_from ::Projects::Integrations::Jira::IssuesFinder::RequestError, with: :render_request_error

        feature_category :integrations

        def index
          params[:state] = params[:state].presence || default_state

          respond_to do |format|
            format.html
            format.json do
              render json: issues_json
            end
          end
        end

        def show
          respond_to do |format|
            format.html do
              @issue_json = issue_json
            end
            format.json do
              render json: issue_json
            end
          end
        end

        private

        def visitor_id
          current_user&.id
        end

        def issues_json
          jira_issues = Kaminari.paginate_array(
            finder.execute,
            limit: finder.per_page,
            total_count: finder.total_count
          )

          ::Integrations::Jira::IssueSerializer.new
            .with_pagination(request, response)
            .represent(jira_issues, project: project)
        end

        def issue_json
          ::Integrations::Jira::IssueDetailSerializer.new
            .represent(project.jira_service.find_issue(params[:id], rendered_fields: true), project: project)
        end

        def finder
          @finder ||= ::Projects::Integrations::Jira::IssuesFinder.new(project, finder_options)
        end

        def finder_options
          options = { sort: set_sort_order }

          # Used by view to highlight active option
          @sort = options[:sort]

          params.permit(::Projects::Integrations::Jira::IssuesFinder.valid_params).merge(options)
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
          return render_404 unless project.jira_issues_integration_available? && project.jira_service.issues_enabled
        end

        # Return the informational message to the user
        def render_integration_error(exception)
          log_exception(exception)

          render json: { errors: [exception.message] }, status: :bad_request
        end

        # Log the specific request error details and return generic message
        def render_request_error(exception)
          log_exception(exception)

          render json: { errors: [_('An error occurred while requesting data from the Jira service')] }, status: :bad_request
        end
      end
    end
  end
end
