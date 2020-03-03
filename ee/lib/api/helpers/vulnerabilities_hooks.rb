# frozen_string_literal: true

module API
  module Helpers
    module VulnerabilitiesHooks
      extend ActiveSupport::Concern

      included do
        after do
          not_found! unless Feature.enabled?(:first_class_vulnerabilities, @project)

          authenticate!
        end
      end
    end
  end
end
