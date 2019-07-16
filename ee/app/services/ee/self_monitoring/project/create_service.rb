# frozen_string_literal: true

module EE
  module SelfMonitoring
    module Project
      module CreateService
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          steps :setup_alertmanager
        end

        private

        def setup_alertmanager
          return success unless License.feature_available?(:prometheus_alerts)

          project_update_result = ::Projects::UpdateService
            .new(project, nil, { alerting_setting_attributes: { token: nil } })
            .execute

          if project_update_result[:status] == :error
            log_error("Could not update alertmanager settings. Errors: #{project.errors.full_messages}")
            return error('Could not update alertmanager settings')
          end

          success
        end
      end
    end
  end
end
