# frozen_string_literal: true

module DastOnDemandScans
  class CreateService < BaseContainerService
    def execute
      return ServiceResponse.error(message: 'Insufficient permissions') unless allowed?

      create_pipeline
    rescue KeyError => err
      ServiceResponse.error(message: err.message.capitalize)
    end

    private

    def allowed?
      container.feature_available?(:security_on_demand_scans)
    end

    def success_response(pipeline)
      pipeline_url = Rails.application.routes.url_helpers.project_pipeline_url(
        container,
        pipeline
      )

      ServiceResponse.success(
        payload: {
          pipeline: pipeline,
          pipeline_url: pipeline_url
        }
      )
    end

    def create_pipeline
      params_result = DastOnDemandScans::ParamsCreateService.new(container, current_user, params).execute

      return params_result unless params_result.success?

      result = ::Ci::RunDastScanService.new(container, current_user).execute(**params_result.payload[:params])

      return success_response(result.payload) if result.success?

      result
    end
  end
end
