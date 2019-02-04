# frozen_string_literal: true

module EE
  module Projects
    module Settings
      module OperationsController
        extend ::Gitlab::Utils::Override
        extend ActiveSupport::Concern

        prepended do
          before_action :authorize_read_prometheus_alerts!,
            only: [:reset_alerting_token]

          respond_to :json, only: [:reset_alerting_token]

          def reset_alerting_token
            result = ::Projects::Operations::UpdateService
              .new(project, current_user, alerting_params)
              .execute

            if result[:status] == :success
              render json: { token: project.alerting_setting.token }
            else
              render json: {}, status: :unprocessable_entity
            end
          end

          helper_method :tracing_setting

          private

          def alerting_params
            { alerting_setting_attributes: { regenerate_token: true } }
          end

          def tracing_setting
            @tracing_setting ||= project.tracing_setting || project.build_tracing_setting
          end
        end

        override :permitted_project_params
        def permitted_project_params
          super.merge(tracing_setting_attributes: [:external_url])
        end
      end
    end
  end
end
