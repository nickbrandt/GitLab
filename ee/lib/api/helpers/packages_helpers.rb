# frozen_string_literal: true

module API
  module Helpers
    module PackagesHelpers
      def require_packages_enabled!
        not_found! unless ::Gitlab.config.packages.enabled
      end

      def authorize_packages_access!(subject)
        require_packages_enabled!
        authorize_packages_feature!(subject)
        authorize_read_package!(subject)
      end

      def authorize_packages_feature!(subject)
        forbidden! unless subject.feature_available?(:packages)
      end

      def authorize_read_package!(subject)
        authorize!(:read_package, subject)
      end

      def authorize_create_package!
        authorize!(:create_package, user_project)
      end

      def authorize_destroy_package!
        authorize!(:destroy_package, user_project)
      end
    end
  end
end
