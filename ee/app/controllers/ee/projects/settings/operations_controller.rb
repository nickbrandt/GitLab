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

          helper_method :tracing_setting, :incident_management_available?

          private

          def render_update_html_response(result)
            if result[:status] == :success
              flash[:notice] = _('Your changes have been saved')
              redirect_to project_settings_operations_path(@project)
            else
              render 'show'
            end
          end

          def alerting_params
            { alerting_setting_attributes: { regenerate_token: true } }
          end

          def tracing_setting
            @tracing_setting ||= project.tracing_setting || project.build_tracing_setting
          end

          def has_tracing_license?
            project.feature_available?(:tracing, current_user)
          end

          def incident_management_available?
            project.feature_available?(:incident_management, current_user)
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

          if incident_management_available?
            permitted_params[:incident_management_setting_attributes] = ::Gitlab::Tracking::IncidentManagement.tracking_keys.keys
          end

          permitted_params
        end

        override :render_update_response
        def render_update_response(result)
          respond_to do |format|
            format.html do
              render_update_html_response(result)
            end

            format.json do
              render_update_json_response(result)
            end
          end
        end

        override :track_events
        def track_events(result)
          super

          if result[:status] == :success
            ::Gitlab::Tracking::IncidentManagement.track_from_params(
              update_params[:incident_management_setting_attributes]
            )

            track_tracing_external_url
          end
        end
      end
    end
  end
end
