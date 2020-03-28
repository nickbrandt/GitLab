# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Parsers
        extend ActiveSupport::Concern

        class_methods do
          def parsers
            super.merge({
                license_management: ::Gitlab::Ci::Parsers::LicenseCompliance::LicenseScanning,
                license_scanning: ::Gitlab::Ci::Parsers::LicenseCompliance::LicenseScanning,
                dependency_scanning: ::Gitlab::Ci::Parsers::Security::DependencyScanning,
                container_scanning: ::Gitlab::Ci::Parsers::Security::ContainerScanning,
                dast: ::Gitlab::Ci::Parsers::Security::Dast,
                sast: ::Gitlab::Ci::Parsers::Security::Sast,
                metrics: ::Gitlab::Ci::Parsers::Metrics::Generic
            })
          end
        end
      end
    end
  end
end
