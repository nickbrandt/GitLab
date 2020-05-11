# frozen_string_literal: true

module Projects
  module Security
    class NetworkPoliciesController < Projects::ApplicationController
      POLLING_INTERVAL = 5_000

      before_action :authorize_read_network_policies!
      before_action :set_polling_interval, only: [:summary]

      def summary
        return not_found unless environment.has_metrics?

        adapter = environment.prometheus_adapter
        return not_found unless adapter.can_query?

        result = adapter.query(
          :packet_flow, environment.deployment_namespace,
          params[:interval] || "minute",
          (Time.parse(params[:from]) rescue 1.hour.ago).to_s,
          (Time.parse(params[:to]) rescue Time.current).to_s
        )

        respond_to do |format|
          format.json do
            if result
              status = result[:success] ? :ok : :bad_request
              render status: status, json: result[:data]
            else
              render status: :accepted, json: {}
            end
          end
        end
      end

      private

      def environment
        @environment ||= project.environments.find(params[:environment_id])
      end

      def set_polling_interval
        Gitlab::PollingInterval.set_header(response, interval: POLLING_INTERVAL)
      end

      def authorize_read_network_policies!
        render_403 unless can?(current_user, :read_threat_monitoring, project)
      end
    end
  end
end
