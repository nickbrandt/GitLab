# frozen_string_literal: true

module Gitlab
  module Auth
    module Smartcard
      extend self

      def enabled?
        ::License.feature_available?(:smartcard_auth) && ::Gitlab.config.smartcard.enabled
      end
    end
  end
end
