# frozen_string_literal: true

module Projects
  module Security
    class DependenciesController < Projects::ApplicationController
      before_action :authorize_read_dependency_list!

      def index
        respond_to do |format|
          format.json do
            ::Gitlab::UsageCounters::DependencyList.increment(project.id)

            render json: serializer.represent(dependencies, build: build)
          end
        end
      end

      private

      def build
        return unless pipeline
        return @build if @build

        @build = pipeline.builds.latest
                  .with_reports(::Ci::JobArtifact.dependency_list_reports)
                  .last
      end

      def can_access_vulnerable?
        return true unless query_params[:filter] == 'vulnerable'

        can?(current_user, :read_project_security_dashboard, project)
      end

      def can_collect_dependencies?
        build&.success? && can_access_vulnerable?
      end

      def collect_dependencies
        found_dependencies = can_collect_dependencies? ? service.execute : []
        ::Gitlab::DependenciesCollection.new(found_dependencies)
      end

      def authorize_read_dependency_list!
        render_403 unless can?(current_user, :read_dependencies, project)
      end

      def dependencies
        @dependencies ||= collect_dependencies
      end

      def match_disallowed(param, value)
        param == :sort_by && !value.in?(::Security::DependencyListService::SORT_BY_VALUES) ||
          param == :sort && !value.in?(::Security::DependencyListService::SORT_VALUES) ||
          param == :filter && !value.in?(::Security::DependencyListService::FILTER_VALUES)
      end

      def pipeline
        @pipeline ||= project.all_pipelines.latest_successful_for_ref(project.default_branch)
      end

      def query_params
        return @permitted_params if @permitted_params

        @permitted_params = params.permit(:sort, :sort_by, :filter).delete_if do |key, value|
          match_disallowed(key, value)
        end
      end

      def serializer
        serializer = ::DependencyListSerializer.new(project: project, user: current_user)
        serializer = serializer.with_pagination(request, response) if params[:page]
        serializer
      end

      def service
        ::Security::DependencyListService.new(pipeline: pipeline, params: query_params)
      end
    end
  end
end
