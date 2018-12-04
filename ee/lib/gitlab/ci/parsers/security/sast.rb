# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class Sast < Common
          extend ::Gitlab::Utils::Override

          DEPRECATED_REPORT_VERSION = "1.2".freeze

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
            Digest::SHA1.hexdigest("#{location['file']}:#{location['start_line']}:#{location['end_line']}")
          end
        end
      end
    end
  end
end
