# frozen_string_literal: true

module EE
  module API
    module Helpers
      module IssuesHelpers
        extend ActiveSupport::Concern

        class_methods do
          extend ::Gitlab::Utils::Override

          override :update_params_at_least_one_of
          def update_params_at_least_one_of
            [*super, :weight]
          end
        end
      end
    end
  end
end
