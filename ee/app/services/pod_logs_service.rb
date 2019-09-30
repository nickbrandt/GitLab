# frozen_string_literal: true

class PodLogsService < ::BaseService
  attr_reader :environment

  K8S_NAME_MAX_LENGTH = 253

  PARAMS = %w(pod_name container_name).freeze

  def initialize(environment, params: {})
    @environment = environment
    @params = filter_params(params.dup).to_hash
  end

  def execute
    pod_name = params['pod_name'].presence
    container_name = params['container_name'].presence

    if pod_name&.length.to_i > K8S_NAME_MAX_LENGTH
      return error(_('pod_name cannot be larger than %{max_length}'\
        ' chars' % { max_length: K8S_NAME_MAX_LENGTH }))
    elsif container_name&.length.to_i > K8S_NAME_MAX_LENGTH
      return error(_('container_name cannot be larger than'\
        ' %{max_length} chars' % { max_length: K8S_NAME_MAX_LENGTH }))
    end

    unless environment.deployment_platform
      return error('No deployment platform')
    end

    # If pod_name is not received as parameter, get the pod logs of the first
    # pod of this environment.
    pod_name ||= environment.pod_names&.first

    pod_logs(pod_name, container_name)
  end

  private

  def pod_logs(pod_name, container_name)
    result = environment.deployment_platform.read_pod_logs(
      pod_name,
      namespace,
      container: container_name
    )

    return unless result

    if result[:status] == :error
      error(result[:error])
    else
      logs = split_by_newline(result[:logs])
      success(logs: logs)
    end
  end

  def filter_params(params)
    params.slice(*PARAMS)
  end

  def split_by_newline(logs)
    return unless logs

    logs.strip.split("\n").as_json
  end

  def namespace
    environment.deployment_namespace
  end
end
