# frozen_string_literal: true

module NetworkPolicies
  class DeployResourceService
    include NetworkPolicies::Responses

    def initialize(policy:, environment:, resource_name: nil)
      @policy = policy
      @platform = environment.deployment_platform
      @kubernetes_namespace = environment.deployment_namespace
      @resource_name = resource_name
    end

    def execute
      return empty_resource_response unless policy
      return no_platform_response unless platform

      setup_resource
      resource = deploy_resource
      policy = Gitlab::Kubernetes::NetworkPolicy.from_resource(resource)
      ServiceResponse.success(payload: policy)
    rescue Kubeclient::HttpError => e
      kubernetes_error_response(e)
    end

    private

    attr_reader :platform, :policy, :resource_name, :resource, :kubernetes_namespace

    def setup_resource
      @resource = policy.generate
      resource[:metadata][:namespace] = kubernetes_namespace
      resource[:metadata][:name] = resource_name if resource_name
    end

    def deploy_resource
      if resource_name
        platform.kubeclient.update_network_policy(resource)
      else
        platform.kubeclient.create_network_policy(resource)
      end
    end
  end
end
