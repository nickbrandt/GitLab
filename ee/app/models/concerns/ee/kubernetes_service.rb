# frozen_string_literal: true

module EE
  module KubernetesService
    extend ActiveSupport::Concern

    LOGS_LIMIT = 500.freeze

    def rollout_status(environment)
      result = with_reactive_cache do |data|
        project = environment.project

        deployments = filter_by_project_environment(data[:deployments], project.full_path_slug, environment.slug)
        pods = filter_by_project_environment(data[:pods], project.full_path_slug, environment.slug) if data[:pods]&.any?

        legacy_deployments = filter_by_label(data[:deployments], { app: environment.slug })

        ::Gitlab::Kubernetes::RolloutStatus.from_deployments(*deployments, pods: pods, legacy_deployments: legacy_deployments)
      end
      result || ::Gitlab::Kubernetes::RolloutStatus.loading
    end

    def calculate_reactive_cache
      result = super
      result[:deployments] = read_deployments if result

      result
    end

    def reactive_cache_updated
      super

      if first_project
        ::Gitlab::EtagCaching::Store.new.tap do |store|
          store.touch(
            ::Gitlab::Routing.url_helpers.project_environments_path(first_project, format: :json))
        end
      end
    end

    def read_deployments
      return [] unless first_project

      kubeclient.get_deployments(namespace: kubernetes_namespace_for(first_project)).as_json
    rescue KubeException => err
      raise err unless err.error_code == 404

      []
    end

    def read_pod_logs(pod_name, container: nil)
      return [] unless first_project

      kubeclient.get_pod_log(pod_name, kubernetes_namespace_for(first_project), container: container, tail_lines: LOGS_LIMIT).as_json
    rescue ::Kubeclient::HttpError => err
      raise err unless err.error_code == 404

      []
    end

    private

    ##
    # TODO: KubernetesService is soon to be removed (https://gitlab.com/gitlab-org/gitlab-ce/issues/39217),
    # after which we can retrieve the project from the cluster in all cases.
    #
    # This currently only works for project-level clusters, this is likely to be fixed as part of
    # https://gitlab.com/gitlab-org/gitlab-ce/issues/61156, which will require logic to select
    # a project from a cluster based on an environment.
    def first_project
      return project unless respond_to?(:cluster)

      cluster.first_project if cluster.project_type?
    end
  end
end
