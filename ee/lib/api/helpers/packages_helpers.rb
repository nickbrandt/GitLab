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
      alias_method :authorize_read_package!, :authorize_download_package!

      def authorize_create_package!
        authorize!(:create_package, user_project)
      end

      def authorize_destroy_package!
        authorize!(:destroy_package, user_project)
      end

      def require_conan_authentication!
        # TODO: implement Conan server authentication
        # To be implemented in https://gitlab.com/gitlab-org/gitlab-ee/issues/12568
        unauthorized!
      end
    end
  end
end
