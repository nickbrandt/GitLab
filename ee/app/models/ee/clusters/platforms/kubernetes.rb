# frozen_string_literal: true

module EE
  module Clusters
    module Platforms
      module Kubernetes
        extend ActiveSupport::Concern

        LOGS_LIMIT = 500.freeze

        def calculate_reactive_cache_for(environment)
          result = super
          result[:deployments] = read_deployments(environment.deployment_namespace) if result

          result
        end

        def rollout_status(environment, data)
          project = environment.project

          deployments = filter_by_project_environment(data[:deployments], project.full_path_slug, environment.slug)
          pods = filter_by_project_environment(data[:pods], project.full_path_slug, environment.slug) if data[:pods]&.any?

          legacy_deployments = filter_by_legacy_label(data[:deployments], project.full_path_slug, environment.slug)

          ::Gitlab::Kubernetes::RolloutStatus.from_deployments(*deployments, pods: pods, legacy_deployments: legacy_deployments)
        end

        def read_pod_logs(pod_name, namespace, container: nil)
          with_reactive_cache(
            'get_pod_log',
            'pod_name' => pod_name,
            'namespace' => namespace,
            'container' => container
          ) do |result|
            result
          end
        end

        def calculate_reactive_cache(request, opts)
          case request
          when 'get_pod_log'
            container = opts['container']
            pod_name = opts['pod_name']
            namespace = opts['namespace']

            handle_exceptions(_('Pod not found'), pod_name: pod_name, container_name: container) do
              container ||= container_names_of(pod_name, namespace).first

              pod_logs(pod_name, namespace, container: container)
            end
          end
        end

        private

        def pod_logs(pod_name, namespace, container: nil)
          logs = kubeclient.get_pod_log(
            pod_name, namespace, container: container, tail_lines: LOGS_LIMIT
          ).body

          {
            logs: logs,
            status: :success,
            pod_name: pod_name,
            container_name: container
          }
        end

        def handle_exceptions(resource_not_found_error_message, opts, &block)
          yield
        rescue Kubeclient::ResourceNotFoundError
          {
            error: resource_not_found_error_message,
            status: :error
          }.merge(opts)
        rescue Kubeclient::HttpError => e
          ::Gitlab::Sentry.track_acceptable_exception(e)

          {
            error: _('Kubernetes API returned status code: %{error_code}') % {
              error_code: e.error_code
            },
            status: :error
          }.merge(opts)
        end

        def container_names_of(pod_name, namespace)
          return [] unless pod_name.present?

          pod_details = kubeclient.get_pod(pod_name, namespace)

          pod_details.spec.containers.collect(&:name)
        end

        def read_deployments(namespace)
          kubeclient.get_deployments(namespace: namespace).as_json
        rescue Kubeclient::ResourceNotFoundError
          []
        end
      end
    end
  end
end
