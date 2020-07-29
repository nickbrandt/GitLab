# frozen_string_literal: true

module Mutations
  module DastOnDemandScans
    class Create < BaseMutation
      InvalidGlobalID = Class.new(StandardError)

      include ResolvesProject

      graphql_name 'DastOnDemandScanCreate'

      field :pipeline_url, GraphQL::STRING_TYPE,
            null: true,
            description: 'URL of the pipeline that was created.'

      argument :full_path, GraphQL::ID_TYPE,
               required: true,
               description: 'The project the site profile belongs to.'

      argument :dast_site_profile_id, GraphQL::ID_TYPE,
               required: true,
               description: 'ID of the site profile to be used for the scan.'

      authorize :run_ondemand_dast_scan

      def resolve(full_path:, dast_site_profile_id:)
        project = authorized_find!(full_path: full_path)
        raise_resource_not_available_error! unless Feature.enabled?(:security_on_demand_scans_feature_flag, project)

        dast_site_profile = find_dast_site_profile(project: project, dast_site_profile_id: dast_site_profile_id)
        dast_site = dast_site_profile.dast_site

        service = Ci::RunDastScanService.new(project, current_user)
        result = service.execute(branch: project.default_branch, target_url: dast_site.url)

        if result.success?
          success_response(project: project, pipeline: result.payload)
        else
          error_response(result)
        end
      end

      private

      def find_object(full_path:)
        resolve_project(full_path: full_path)
      end

      def find_dast_site_profile(project:, dast_site_profile_id:)
        global_id = GlobalID.parse(dast_site_profile_id)

        raise InvalidGlobalID.new('Incorrect class') unless global_id.model_class == DastSiteProfile

        project
          .dast_site_profiles
          .with_dast_site
          .find(global_id.model_id)
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

      def error_response(result)
        { errors: result.errors }
      end
    end
  end
end
