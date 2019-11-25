# frozen_string_literal: true

module API
  module Helpers
    module VulnerabilitiesHelpers
      def find_and_authorize_vulnerability!(action)
        find_vulnerability!.tap do |vulnerability|
          authorize! action, vulnerability.project
        end
      end
    end
  end
end
