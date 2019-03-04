# frozen_string_literal: true

module EE
  module API
    module Variables
      extend ActiveSupport::Concern

      prepended do
        helpers do
          extend ::Gitlab::Utils::Override

          override :filter_variable_parameters
          def filter_variable_parameters(params)
            unless user_project.feature_available?(:variable_environment_scope)
              params.delete(:environment_scope)
            end

            params
          end
        end
      end
    end
  end
end
