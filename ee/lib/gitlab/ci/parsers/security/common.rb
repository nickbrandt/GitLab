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

            report_data["vulnerabilities"].each do |vulnerability|
              create_vulnerability(report, vulnerability, report_data["version"])
            end
          rescue JSON::ParserError
            raise SecurityReportParserError, 'JSON parsing failed'
          rescue => e
            Gitlab::Sentry.track_exception(e)
            raise SecurityReportParserError, "#{report.type} security report parsing failed"
          end

          protected

          def parse_report(json_data)
            JSON.parse!(json_data)
          end

          def create_vulnerability(report, data, version)
            scanner = create_scanner(report, data['scanner'] || mutate_scanner_tool(data['tool']))
            identifiers = create_identifiers(report, data['identifiers'])

            report.add_occurrence(
              uuid: SecureRandom.uuid,
              report_type: report.type,
              name: data['message'],
              primary_identifier: identifiers.first,
              project_fingerprint: generate_project_fingerprint(data['cve']),
              location_fingerprint: generate_location_fingerprint(data['location']),
              severity: parse_level(data['severity']),
              confidence: parse_level(data['confidence']),
              scanner: scanner,
              identifiers: identifiers,
              raw_metadata: data.to_json,
              metadata_version: version
            )
          end

          def create_scanner(report, scanner)
            return unless scanner.is_a?(Hash)

            report.add_scanner(
              external_id: scanner['id'],
              name: scanner['name'])
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
              external_type: identifier['type'],
              external_id: identifier['value'],
              name: identifier['name'],
              fingerprint: generate_identifier_fingerprint(identifier),
              url: identifier['url'])
          end

          def mutate_scanner_tool(tool)
            { 'id' => tool, 'name' => tool.capitalize } if tool
          end

          def parse_level(input)
            input.blank? ? 'undefined' : input.downcase
          end

          def generate_project_fingerprint(compare_key)
            Digest::SHA1.hexdigest(compare_key)
          end

          def generate_identifier_fingerprint(identifier)
            Digest::SHA1.hexdigest("#{identifier['type']}:#{identifier['value']}")
          end

          def generate_location_fingerprint(location)
            raise NotImplementedError
          end
        end
      end
    end
  end
end
