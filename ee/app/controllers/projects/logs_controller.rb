# frozen_string_literal: true

module Projects
  class LogsController < Projects::ApplicationController
    before_action :authorize_read_pod_logs!
    before_action :environment
    before_action do
      push_frontend_feature_flag(:enable_cluster_application_elastic_stack)
    end

    def index
      if environment.nil?
        render :empty_logs
      else
        render :index
      end
    end

    def k8s
      ::Gitlab::UsageCounters::PodLogs.increment(project.id)
      ::Gitlab::PollingInterval.set_header(response, interval: 3_000)

      result = PodLogsService.new(environment, params: filter_params).execute

      if result[:status] == :processing
        head :accepted
      elsif result[:status] == :success
        render json: result
      else
        render status: :bad_request, json: result
      end
    end

    private

    def index_params
      params.permit(:environment_name)
    end

    def filter_params
      params.permit(:container_name, :pod_name, :search)
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
