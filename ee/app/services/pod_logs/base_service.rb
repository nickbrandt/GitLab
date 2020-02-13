# frozen_string_literal: true

module PodLogs
  class BaseService < ::BaseService
    include ReactiveCaching
    include Stepable

    attr_reader :environment, :params

    CACHE_KEY_GET_POD_LOG = 'get_pod_log'
    K8S_NAME_MAX_LENGTH = 253

    SUCCESS_RETURN_KEYS = %i(status logs pod_name container_name pods).freeze

    def id
      environment.id
    end

    def initialize(environment, params: {})
      @environment = environment
      @params = filter_params(params.dup.stringify_keys).to_hash
    end

    def execute
      with_reactive_cache(
        CACHE_KEY_GET_POD_LOG,
        params
      ) do |result|
        result
      end
    end

    def calculate_reactive_cache(request, _opts)
      case request
      when CACHE_KEY_GET_POD_LOG
        execute_steps
      else
        exception = StandardError.new('Unknown reactive cache request')
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(exception, request: request)
        error(_('Unknown cache key'))
      end
    end

    def reactive_cache_updated(request, _opts)
      case request
      when CACHE_KEY_GET_POD_LOG
        ::Gitlab::EtagCaching::Store.new.tap do |store|
          store.touch(etag_path)
        end
      end
    end

    private

    def valid_params
      %w(pod_name container_name)
    end

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

    def get_raw_pods(result)
      namespace = environment.deployment_namespace
      result[:raw_pods] = environment.deployment_platform.kubeclient.get_pods(namespace: namespace)

      success(result)
    end

    def get_pod_names(result)
      result[:pods] = result[:raw_pods].map(&:metadata).map(&:name)

      success(result)
    end

    def check_pod_name(result)
      # If pod_name is not received as parameter, get the pod logs of the first
      # pod of this environment.
      result[:pod_name] ||= result[:pods].first

      unless result[:pod_name]
        return error(_('No pods available'))
      end

      unless result[:pods].include?(result[:pod_name])
        return error(_('Pod does not exist'))
      end

      success(result)
    end

    def check_container_name(result)
      pod_details = result[:raw_pods].first { |p| p.metadata.name == result[:pod_name] }
      containers = pod_details.spec.containers.map(&:name)

      # select first container if not specified
      result[:container_name] ||= containers.first

      unless result[:container_name]
        return error(_('No containers available'))
      end

      unless containers.include?(result[:container_name])
        return error(_('Container does not exist'))
      end

      success(result)
    end

    def pod_logs(result)
      raise NotImplementedError
    end

    def etag_path
      raise NotImplementedError
    end

    def filter_return_keys(result)
      result.slice(*SUCCESS_RETURN_KEYS)
    end

    def filter_params(params)
      params.slice(*valid_params)
    end
  end
end
