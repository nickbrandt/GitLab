# frozen_string_literal: true

module Projects
  module Security
    class DependenciesController < Projects::ApplicationController
      SORT_BY_PERMITTED_VALUES = %w(name type).freeze
      SORT_PERMITTED_VALUES    = %w(asc desc).freeze

      before_action :ensure_dependency_list_feature_available

      def index
        respond_to do |format|
          format.json do
            render json: report
          end
        end
      end

      private

      def build
        @build ||= pipeline.builds.latest
                  .with_reports(::Ci::JobArtifact.dependency_list_reports)
                  .last
      end

      def ensure_dependency_list_feature_available
        render_404 unless project.feature_available?(:dependency_list)
      end

      def found_dependencies
        @dependencies ||= pipeline ? service.execute : []
      end

      def job_path
        # "Gitlab::Routing.url_helpers.project_build_path(@project, build.id, format: :json)"
        build ? project_build_path(@project, build.id) : ''
      end

      def paginated_dependencies
        params[:page] ? Kaminari.paginate_array(found_dependencies).page(params[:page]) : found_dependencies
      end

      def pipeline
        @pipeline ||= project.all_pipelines.latest_successful_for(project.default_branch)
      end

      def query_params
        params.permit(:sort, :sort_by).delete_if do |key, value|
          key == :sort_by && !value.in?(::Security::DependencyListService::SORT_BY_VALUES) ||
            key == :sort && !value.in?(::Security::DependencyListService::SORT_VALUES)
        end
      end

      def report
        {
          dependencies: paginated_dependencies,
          report: {
            status: status,
            job_path: job_path
          }
        }
      end

      def status
        if build
          if found_dependencies.any?
            :ok
          else
            :job_failed
          end
        else
          :job_not_set_up
        end
      end

      def service
        ::Security::DependencyListService.new(pipeline: pipeline, params: query_params)
      end
    end
  end
end
