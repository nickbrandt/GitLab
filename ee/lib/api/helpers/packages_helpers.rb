# frozen_string_literal: true

module API
  module Helpers
    module PackagesHelpers
      def require_packages_enabled!
        not_found! unless ::Gitlab.config.packages.enabled
      end

      def authorize_packages_feature!
        forbidden! unless user_project.feature_available?(:packages)
      end

      def authorize_download_package!
        authorize!(:read_package, user_project)
      end

      def authorize_create_package!
        authorize!(:create_package, user_project)
      end
    end
  end
end
