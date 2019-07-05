# frozen_string_literal: true

module Gitlab
  module Auth
    module Smartcard
      extend self

      def enabled?
        ::License.feature_available?(:smartcard_auth) && ::Gitlab.config.smartcard.enabled
      end

      def required_for_git_access?
        self.enabled? && ::Gitlab.config.smartcard.required_for_git_access
      end
    end
  end
end
