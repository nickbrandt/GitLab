# frozen_string_literal: true

class PodLogsService < ::BaseService
  include Stepable

  attr_reader :environment

  K8S_NAME_MAX_LENGTH = 253

  PARAMS = %w(pod_name container_name search).freeze

  SUCCESS_RETURN_KEYS = [:status, :logs, :pod_name, :container_name, :pods, :enable_advanced_querying].freeze

  steps :check_param_lengths,
    :check_deployment_platform,
    :check_pod_names,
    :check_pod_name,
    :pod_logs,
    :filter_return_keys

  def initialize(environment, params: {})
    @environment = environment
    @params = filter_params(params.dup).to_hash
  end

  def execute
    execute_steps
  end

  private

  def check_param_lengths(_result)
    pod_name = params['pod_name'].presence
    container_name = params['container_name'].presence

    if pod_name&.length.to_i > K8S_NAME_MAX_LENGTH
      return error(_('pod_name cannot be larger than %{max_length}'\
        ' chars' % { max_length: K8S_NAME_MAX_LENGTH }))
    elsif container_name&.length.to_i > K8S_NAME_MAX_LENGTH
      return error(_('container_name cannot be larger than'\
        ' %{max_length} chars' % { max_length: K8S_NAME_MAX_LENGTH }))
    end

    success(pod_name: pod_name, container_name: container_name)
  end

  def check_deployment_platform(result)
    unless environment.deployment_platform
      return error(_('No deployment platform available'))
    end

    success(result)
  end

  def check_pod_names(result)
    result[:pods] = environment.pod_names

    return { status: :processing } unless result[:pods]

    success(result)
  end

  def check_pod_name(result)
    # If pod_name is not received as parameter, get the pod logs of the first
    # pod of this environment.
    result[:pod_name] ||= result[:pods].first

    unless result[:pod_name]
      return error(_('No pods available'))
    end

    success(result)
  end

  def pod_logs(result)
    response = environment.deployment_platform.read_pod_logs(
      environment.id,
      result[:pod_name],
      namespace,
      container: result[:container_name],
      search: params['search']
    )

    return { status: :processing } unless response

    result.merge!(response.slice(:pod_name, :container_name, :logs, :enable_advanced_querying))

    if response[:status] == :error
      error(response[:error]).reverse_merge(result)
    else
      success(result)
    end
  end

  def filter_return_keys(result)
    result.slice(*SUCCESS_RETURN_KEYS)
  end

  def filter_params(params)
    params.slice(*PARAMS)
  end

  def namespace
    environment.deployment_namespace
  end
end
