# frozen_string_literal: true

module EE
  module API
    module Validations
      module CheckAssigneesCount
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          private

          def param_allowed?(attr_name, params)
            params[attr_name].size <= 1 || License.feature_available?(:multiple_issue_assignees)
          end
        end
      end
    end
  end
end
