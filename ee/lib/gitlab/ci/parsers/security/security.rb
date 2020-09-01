# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class Security < Common
          include ::Gitlab::Ci::Parsers::Security::Concerns::DeprecatedSyntax

          DEPRECATED_REPORT_VERSION = "1.2".freeze

          private

          def create_vulnerability(report, data, version)
            scanner = create_scanner(report, data['scanner'] || mutate_scanner_tool(data['tool']))
            identifiers = create_identifiers(report, data['identifiers'])
            report.add_finding(
              ::Gitlab::Ci::Reports::Security::Finding.new(
                uuid: SecureRandom.uuid,
                report_type: report.type,
                name: data['message'],
                compare_key: data['cve'] || '',
                location: create_location(data['tracking'] || {}),
                severity: parse_severity_level(data['severity']&.downcase),
                confidence: parse_confidence_level(data['confidence']&.downcase),
                scanner: scanner,
                identifiers: identifiers,
                raw_metadata: data.to_json,
                metadata_version: version))
          end

          def create_location(tracking_data)
            type = tracking_data['type']
            if type == 'source'
              ::Gitlab::Ci::Reports::Security::Tracking::Source.new(
                file_path: tracking_data['file'],
                start_line: tracking_data['start_line'],
                end_line: tracking_data['end_line'])
            elsif type == 'hash'
              ::Gitlab::Ci::Reports::Security::Tracking::Hashed.new(tracking_data['data'])
            else
              ::Gitlab::Ci::Reports::Security::Tracking::Hashed.new(Time.now)
            end
          end
        end
      end
    end
  end
end
