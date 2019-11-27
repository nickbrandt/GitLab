# frozen_string_literal: true

module EE
  module Projects
    module EnvironmentsController
      extend ActiveSupport::Concern

      prepended do
        before_action :authorize_read_pod_logs!, only: [:k8s_pod_logs, :logs]
        before_action :environment_ee, only: [:k8s_pod_logs, :logs]
        before_action :authorize_create_environment_terminal!, only: [:terminal]
      end

      def logs_redirect
        environment = project.default_environment

        if environment
          redirect_to logs_project_environment_path(project, environment)
        else
          render :empty_logs
        end
      end

      def logs
      end

      def k8s_pod_logs
        respond_to do |format|
          format.json do
            ::Gitlab::UsageCounters::PodLogs.increment(project.id)
            ::Gitlab::PollingInterval.set_header(response, interval: 3_000)

            result = PodLogsService.new(environment, params: params.permit!).execute

            if result[:status] == :processing
              head :accepted
            elsif result[:status] == :success
              render json: result
            else
              render status: :bad_request, json: result
            end
          end
        end
      end

      private

      def environment_ee
        environment
      end

      def authorize_create_environment_terminal!
        return render_404 unless can?(current_user, :create_environment_terminal, environment)
      end
    end
  end
end
