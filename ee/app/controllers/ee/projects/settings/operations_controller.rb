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

          def has_tracing_license?
            project.feature_available?(:tracing, current_user)
          end

          def track_tracing_external_url
            external_url_previous_change = project&.tracing_setting&.external_url_previous_change
            return unless external_url_previous_change
            return unless external_url_previous_change[0].blank? && external_url_previous_change[1].present?

            ::Gitlab::Tracking.event('project:operations:tracing', "external_url_populated")
          end
        end

        override :permitted_project_params
        def permitted_project_params
          permitted_params = super

          if has_tracing_license?
            permitted_params[:tracing_setting_attributes] = [:external_url]
          end

          permitted_params
        end

        override :track_events
        def track_events(result)
          super

          track_tracing_external_url if result[:status] == :success
        end
      end
    end
  end
end
