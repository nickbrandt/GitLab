# frozen_string_literal: true

module Projects
  class LogsController < Projects::ApplicationController
    before_action :authorize_read_pod_logs!
    before_action :environment

    def index
      if environment.nil?
        render :empty_logs
      else
        render :index
      end
    end

    def k8s
      render_logs(::PodLogs::KubernetesService, k8s_params)
    end

    def elasticsearch
      render_logs(::PodLogs::ElasticsearchService, elasticsearch_params)
    end

    private

    def render_logs(service, permitted_params)
      ::Gitlab::UsageCounters::PodLogs.increment(project.id)
      ::Gitlab::PollingInterval.set_header(response, interval: 3_000)

      result = service.new(environment, params: permitted_params).execute

      if result.nil?
        head :accepted
      elsif result[:status] == :success
        render json: result
      else
        render status: :bad_request, json: result
      end
    end

    def index_params
      params.permit(:environment_name)
    end

    def k8s_params
      params.permit(:container_name, :pod_name)
    end

    def elasticsearch_params
      params.permit(:container_name, :pod_name, :search, :start, :end)
    end

    def environment
      @environment ||= if index_params.key?(:environment_name)
                         EnvironmentsFinder.new(project, current_user, name: index_params[:environment_name]).find.first
                       else
                         project.default_environment
                       end
    end
  end
end
