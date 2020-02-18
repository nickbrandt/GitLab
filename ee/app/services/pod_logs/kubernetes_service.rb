# frozen_string_literal: true

module PodLogs
  class KubernetesService < BaseService
    LOGS_LIMIT = 500.freeze

    steps :check_param_lengths,
          :check_deployment_platform,
          :get_raw_pods,
          :get_pod_names,
          :check_pod_name,
          :check_container_name,
          :pod_logs,
          :filter_return_keys

    self.reactive_cache_worker_finder = ->(id, _cache_key, params) { new(Environment.find(id), params: params) }

    private

    def pod_logs(result)
      logs = environment.deployment_platform.kubeclient.get_pod_log(
        result[:pod_name],
        environment.deployment_namespace,
        container: result[:container_name],
        tail_lines: LOGS_LIMIT,
        timestamps: true
      ).body

      result[:logs] = logs.strip.lines(chomp: true).map do |line|
        # message contains a RFC3339Nano timestamp, then a space, then the log line.
        # resolution of the nanoseconds can vary, so we split on the first space
        values = line.split(' ', 2)
        {
          timestamp: values[0],
          message: values[1]
        }
      end

      success(result)
    rescue Kubeclient::ResourceNotFoundError
      error(_('Pod not found'))
    rescue Kubeclient::HttpError => e
      ::Gitlab::ErrorTracking.track_exception(e)

      error(_('Kubernetes API returned status code: %{error_code}') % {
        error_code: e.error_code
      })
    end
  end
end
