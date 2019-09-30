# frozen_string_literal: true

module EE
  module Projects
    module EnvironmentsController
      extend ActiveSupport::Concern

      prepended do
        before_action :authorize_read_pod_logs!, only: [:logs]
        before_action :environment_ee, only: [:logs]
        before_action :authorize_create_environment_terminal!, only: [:terminal]
      end

      def logs
        respond_to do |format|
          format.html
          format.json do
            ::Gitlab::UsageCounters::PodLogs.increment(project.id)
            ::Gitlab::PollingInterval.set_header(response, interval: 3_000)

            result = PodLogsService.new(environment, params: params.permit!).execute

            if result.nil?
              head :accepted
            elsif result[:status] == :success
              render json: {
                pods: environment.pod_names,
                logs: result[:logs],
                message: result[:message]
              }
            else
              render status: :bad_request, json: {
                pods: environment.pod_names,
                message: result[:message]
              }
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
