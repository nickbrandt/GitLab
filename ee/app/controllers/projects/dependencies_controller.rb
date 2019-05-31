# frozen_string_literal: true

module Projects
  class DependenciesController < Projects::ApplicationController
    SORT_BY_PERMITTED_VALUES = %w(name type).freeze
    SORT_PERMITTED_VALUES = %w(asc desc).freeze

    before_action :ensure_bill_of_materials_feature_flag_enabled

    def index
      respond_to do |format|
        format.json do
          render json: report
        end
      end
    end

    private

    def ensure_bill_of_materials_feature_flag_enabled
      render_404 unless Feature.enabled?(:bill_of_materials, default_enabled: false)
    end

    def found_dependencies
      finder.execute
    end

    def finder
      ::Security::DependenciesFinder.new(project: @project, params: query_params)
    end

    def query_params
      params.permit(:sort, :sort_by).delete_if do |key, value|
        key == :sort_by && !value.in?(::Security::DependenciesFinder::SORT_BY_VALUES) ||
          key == :sort && !value.in?(::Security::DependenciesFinder::SORT_VALUES)
      end
    end

    # TODO: add proper implementation of edge cases handling
    # format: { report: 'failed' }
    # after we'll have more then just mock data
    # reference: https://gitlab.com/gitlab-org/gitlab-ee/issues/10075#note_164915787
    def paginated_dependencies
      list = found_dependencies
      if params[:page]
        list = Kaminari.paginate_array(found_dependencies).page(params[:page])
      end
      list
    end

    def report
      {
        dependencies: paginated_dependencies,
        report: {
          status: finder.status,
          job_path: Gitlab::Routing.url_helpers.project_build_path(@project, build.id, format: :json)
        }
      }
    end

    def build
      pipeline = @project.all_pipelines.latest_successful_for(project.default_branch)
      pipeline.builds
                .where(name: SCANNING_JOB_NAME)
                .latest
                .with_reports(::Ci::JobArtifact.dependency_list_reports)
                .last
    end
  end
end
