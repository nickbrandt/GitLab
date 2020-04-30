# frozen_string_literal: true

module NetworkPolicies
  class ResourcesService
    include NetworkPolicies::Responses

    def initialize(environment:)
      @platform = environment.deployment_platform
      @kubernetes_namespace = environment.deployment_namespace
    end

    def execute
      return no_platform_response unless @platform

      policies = @platform.kubeclient
        .get_network_policies(namespace: @kubernetes_namespace)
        .map { |resource| Gitlab::Kubernetes::NetworkPolicy.from_resource(resource) }
      ServiceResponse.success(payload: policies)
    rescue Kubeclient::HttpError => e
      kubernetes_error_response(e)
    end
  end
end
