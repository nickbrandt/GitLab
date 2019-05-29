# frozen_string_literal: true

module EE
  module API
    module Helpers
      module VariablesHelpers
        extend ActiveSupport::Concern

        prepended do
          params :optional_params_ee do
            optional :environment_scope, type: String, desc: 'The environment_scope of the variable'
          end
        end
      end
    end
  end
end
