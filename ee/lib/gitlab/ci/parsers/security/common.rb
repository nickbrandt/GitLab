# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class Common
          SecurityReportParserError = Class.new(Gitlab::Ci::Parsers::ParserError)

          def parse!(json_data, report)
            report_data = parse_report(json_data)
            raise SecurityReportParserError, "Invalid report format" unless report_data.is_a?(Hash)

            collate_remediations(report_data).each do |vulnerability|
              create_vulnerability(report, vulnerability, report_data["version"])
            end
          rescue JSON::ParserError
            raise SecurityReportParserError, 'JSON parsing failed'
          rescue => e
            Gitlab::Sentry.track_and_raise_for_dev_exception(e)
            raise SecurityReportParserError, "#{report.type} security report parsing failed"
          end

          protected

          def parse_report(json_data)
            JSON.parse!(json_data)
          end

          # map remediations to relevant vulnerabilities
          def collate_remediations(report_data)
            return report_data["vulnerabilities"] || [] unless report_data["remediations"]

            report_data["vulnerabilities"].map do |vulnerability|
              # Grab the first available remediation.
              remediation = report_data["remediations"].find do |remediation|
                remediation["fixes"].any? { |fix| fix["cve"] == vulnerability["cve"] }
              end

              vulnerability.merge("remediations" => [remediation])
            end
          end

          def create_vulnerability(report, data, version)
            scanner = create_scanner(report, data['scanner'] || mutate_scanner_tool(data['tool']))
            identifiers = create_identifiers(report, data['identifiers'])
            report.add_occurrence(
              ::Gitlab::Ci::Reports::Security::Occurrence.new(
                uuid: SecureRandom.uuid,
                report_type: report.type,
                name: data['message'],
                compare_key: data['cve'] || '',
                location: create_location(data['location'] || {}),
                severity: parse_level(data['severity']),
                confidence: parse_level(data['confidence']),
                scanner: scanner,
                identifiers: identifiers,
                raw_metadata: data.to_json,
                metadata_version: version))
          end

          def create_scanner(report, scanner)
            return unless scanner.is_a?(Hash)

            report.add_scanner(
              ::Gitlab::Ci::Reports::Security::Scanner.new(
                external_id: scanner['id'],
                name: scanner['name']))
          end

          def create_identifiers(report, identifiers)
            return [] unless identifiers.is_a?(Array)

            identifiers.map do |identifier|
              create_identifier(report, identifier)
            end.compact
          end

          def create_identifier(report, identifier)
            return unless identifier.is_a?(Hash)

            report.add_identifier(
              ::Gitlab::Ci::Reports::Security::Identifier.new(
                external_type: identifier['type'],
                external_id: identifier['value'],
                name: identifier['name'],
                url: identifier['url']))
          end

          # TODO: this can be removed as of `12.0`
          def mutate_scanner_tool(tool)
            { 'id' => tool, 'name' => tool.capitalize } if tool
          end

          def parse_level(input)
            input.blank? ? 'undefined' : input.downcase
          end

          def create_location(location_data)
            raise NotImplementedError
          end
        end
      end
    end
  end
end
