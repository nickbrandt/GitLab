# frozen_string_literal: true

module Mutations
  module Pipelines
    class RunDastScan < BaseMutation
      include ResolvesProject

      graphql_name 'RunDASTScan'

      field :pipeline_url, GraphQL::STRING_TYPE,
            null: true,
            description: 'URL of the pipeline that was created.'

      argument :project_path, GraphQL::ID_TYPE,
               required: true,
               description: 'The project the DAST scan belongs to.'

      argument :target_url, GraphQL::STRING_TYPE,
               required: true,
               description: 'The URL of the target to be scanned.'

      argument :branch, GraphQL::STRING_TYPE,
               required: true,
               description: 'The branch to be associated with the scan.'

      argument :scan_type, Types::DastScanTypeEnum,
               required: true,
               description: 'The type of scan to be run.'

      authorize :create_pipeline

      def resolve(project_path:, target_url:, branch:, scan_type:)
        project = authorized_find!(full_path: project_path)
        raise_resource_not_available_error! unless Feature.enabled?(:security_on_demand_scans_feature_flag, project)

        service = Ci::RunDastScanService.new(project: project, user: current_user)
        pipeline = service.execute(branch: branch, target_url: target_url)
        success_response(project: project, pipeline: pipeline)
      rescue *Ci::RunDastScanService::EXCEPTIONS => err
        error_response(err)
      end

      private

      def find_object(full_path:)
        resolve_project(full_path: full_path)
      end

      def success_response(project:, pipeline:)
        pipeline_url = Rails.application.routes.url_helpers.project_pipeline_url(
          project,
          pipeline
        )
        {
          errors: [],
          pipeline_url: pipeline_url
        }
      end

      def error_response(err)
        { errors: [err.message] }
      end
    end
  end
end
