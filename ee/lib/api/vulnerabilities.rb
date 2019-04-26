# frozen_string_literal: true

module API
  class Vulnerabilities < Grape::API
    include PaginationParams

    # HACK: RequestProxy needed because `request.current_user` not set for Grape::API
    class RequestProxy < SimpleDelegator
      attr_reader :current_user

      def initialize(req, current_user)
        @current_user = current_user
        super(req)
      end
    end

    helpers do
      def vulnerability_occurrences_by(params)
        pipeline = params[:project].latest_pipeline_with_security_reports

        return [] unless pipeline

        Security::PipelineVulnerabilitiesFinder.new(pipeline: pipeline, params: params).execute
      end
    end

    before do
      authenticate!
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of project vulnerabilities' do
        success ::Vulnerabilities::OccurrenceEntity
      end

      params do
        optional :report_type, type: String, desc: 'The type of report vulnerability belongs to', default: ::Vulnerabilities::Occurrence.report_types.keys
        use :pagination
      end

      get ':id/vulnerabilities' do
        project = Project.find(params[:id])

        not_found!('Project') unless project && can?(current_user, :read_project_security_dashboard, project)

        vulnerability_occurrences = Kaminari.paginate_array(
          vulnerability_occurrences_by(params.merge(project: project))
        )

        present paginate(vulnerability_occurrences),
          with: ::Vulnerabilities::OccurrenceEntity,
          request: RequestProxy.new(request, current_user)
      end
    end
  end
end
