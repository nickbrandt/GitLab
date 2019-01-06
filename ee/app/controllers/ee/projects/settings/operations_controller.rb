# frozen_string_literal: true

module EE
  module Projects
    module Settings
      module OperationsController
        extend ::Gitlab::Utils::Override
        extend ActiveSupport::Concern

        prepended do
          helper_method :tracing_setting

          def tracing_setting
            @tracing_setting ||= project.tracing_setting || project.build_tracing_setting
          end

          private :tracing_setting
        end

        override :permitted_project_params
        def permitted_project_params
          super.merge(tracing_setting_attributes: [:external_url])
        end
      end
    end
  end
end
