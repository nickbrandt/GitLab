# frozen_string_literal: true

module API
  module Helpers
    module VariablesHelpers
      extend ActiveSupport::Concern
      extend Grape::API::Helpers

      params :optional_params_ee do
      end
    end
  end
end

API::Helpers::VariablesHelpers.prepend_if_ee('EE::API::Helpers::VariablesHelpers')
