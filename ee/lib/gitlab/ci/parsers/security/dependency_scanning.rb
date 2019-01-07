# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class DependencyScanning < Common
          extend ::Gitlab::Utils::Override

          DEPRECATED_REPORT_VERSION = "1.3".freeze

          private

          override :parse_report
          def parse_report(json_data)
            report = super

            if report.is_a?(Array)
              report = {
                "version" => DEPRECATED_REPORT_VERSION,
                "vulnerabilities" => report
              }
            end

            report
          end

          def generate_location_fingerprint(location)
            Digest::SHA1.hexdigest("#{location['file']}:#{location.dig('dependency', 'package', 'name')}")
          end
        end
      end
    end
  end
end
