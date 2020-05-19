# frozen_string_literal: true

module NetworkPolicies
  class DeleteResourceService
    include NetworkPolicies::Responses

    def initialize(resource_name:, environment:)
      @resource_name = resource_name
      @platform = environment.deployment_platform
      @kubernetes_namespace = environment.deployment_namespace
    end

    def execute
      return no_platform_response unless @platform

      @platform.kubeclient.delete_network_policy(@resource_name, @kubernetes_namespace)
      ServiceResponse.success
    rescue Kubeclient::HttpError => e
      kubernetes_error_response(e)
    end
  end
end
