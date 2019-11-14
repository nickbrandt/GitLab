# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class ContainerScanning < Common
          include Security::Concerns::DeprecatedSyntax

          DEPRECATED_REPORT_VERSION = "1.3".freeze

          def parse_report(json_data)
            report = super

            return format_deprecated_report(report) if deprecated?(report)

            report
          end

          private

          # Transforms the clair-scanner JSON report into the expected format
          # TODO: remove the following block when we no longer need to support legacy
          # clair-scanner data. See https://gitlab.com/gitlab-org/gitlab/issues/35442
          def format_deprecated_report(data)
            unapproved = data['unapproved']
            formatter = Formatters::DeprecatedContainerScanning.new(data['image'])

            vulnerabilities = data['vulnerabilities'].map do |vulnerability|
              # We only report unapproved vulnerabilities
              next unless unapproved.include?(vulnerability['vulnerability'])

              formatter.format(vulnerability)
            end.compact

            { "vulnerabilities" => vulnerabilities, "version" => DEPRECATED_REPORT_VERSION }
          end

          def deprecated?(data)
            data['image']
          end

          def create_location(location_data)
            ::Gitlab::Ci::Reports::Security::Locations::ContainerScanning.new(
              image: location_data['image'],
              operating_system: location_data['operating_system'],
              package_name: location_data.dig('dependency', 'package', 'name'),
              package_version: location_data.dig('dependency', 'version'))
          end
        end
      end
    end
  end
end
