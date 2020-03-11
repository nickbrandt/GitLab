# frozen_string_literal: true

module EE
  module Gitlab
    module Middleware
      module Multipart
        module Handler
          extend ::Gitlab::Utils::Override

          private

          override :allowed_paths
          def allowed_paths
            paths = super
            packages_config = ::Gitlab.config.packages
            if allow_packages_storage_path?(packages_config)
              paths << ::Packages::PackageFileUploader.workhorse_upload_path
            end

            paths
          end

          def allow_packages_storage_path?(packages_config)
            return unless packages_config.enabled
            return unless packages_config['storage_path']
            return if packages_config.object_store.enabled && packages_config.object_store.direct_upload

            true
          end
        end
      end
    end
  end
end
