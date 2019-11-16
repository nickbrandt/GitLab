# frozen_string_literal: true

# TODO: remove this class when we no longer need to support legacy
# clair-scanner data. See https://gitlab.com/gitlab-org/gitlab/issues/35442
module Gitlab
  module Ci
    module Parsers
      module Security
        module Formatters
          class DeprecatedContainerScanning
            def initialize(image)
              @image = image
            end

            def format(vulnerability)
              formatted_vulnerability = DeprecatedFormattedContainerScanningVulnerability.new(vulnerability)

              {
                'category' => 'container_scanning',
                'message' => formatted_vulnerability.message,
                'description' => formatted_vulnerability.description,
                'cve' => formatted_vulnerability.cve,
                'severity' => formatted_vulnerability.severity,
                'solution' => formatted_vulnerability.solution,
                'confidence' => 'Unknown',
                'location' => {
                  'image' => image,
                  'operating_system' => formatted_vulnerability.operating_system,
                  'dependency' => {
                    'package' => {
                      'name' => formatted_vulnerability.package_name
                    },
                    'version' => formatted_vulnerability.version
                  }
                },
                'scanner' => { 'id' => 'clair', 'name' => 'Clair' },
                'identifiers' => [
                  {
                    'type' => 'cve',
                    'name' => formatted_vulnerability.cve,
                    'value' => formatted_vulnerability.cve,
                    'url' => formatted_vulnerability.url
                  }
                ],
                'links' => [{ 'url' => formatted_vulnerability.url }]
              }
            end

            private

            attr_reader :image
          end
        end
      end
    end
  end
end
