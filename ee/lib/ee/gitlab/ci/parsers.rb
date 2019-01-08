# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Parsers
        extend ActiveSupport::Concern

        class_methods do
          def parsers
            super.merge({
                license_management: ::Gitlab::Ci::Parsers::LicenseManagement::LicenseManagement,
                dependency_scanning: ::Gitlab::Ci::Parsers::Security::DependencyScanning,
                container_scanning: ::Gitlab::Ci::Parsers::Security::ContainerScanning,
                sast: ::Gitlab::Ci::Parsers::Security::Sast
            })
          end
        end
      end
    end
  end
end
