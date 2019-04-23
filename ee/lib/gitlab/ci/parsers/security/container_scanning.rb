# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class ContainerScanning < Common
          include Security::Concerns::DeprecatedSyntax

          DEPRECATED_REPORT_VERSION = "1.3".freeze

          def parse!(json_data, report)
            vulnerabilities = format_report(JSON.parse!(json_data))

            vulnerabilities.each do |vulnerability|
              create_vulnerability(report, vulnerability, DEPRECATED_REPORT_VERSION)
            end
          rescue JSON::ParserError
            raise SecurityReportParserError, 'JSON parsing failed'
          rescue
            raise SecurityReportParserError, "#{report.type} security report parsing failed"
          end

          private

          # Transforms the Clair JSON report into the expected format
          def format_report(data)
            vulnerabilities = data['vulnerabilities']
            unapproved = data['unapproved']
            results = []

            vulnerabilities.each do |vulnerability|
              # We only report unapproved vulnerabilities
              next unless unapproved.include?(vulnerability['vulnerability'])

              results.append(format_vulnerability(vulnerability, data['image']))
            end

            results
          end

          def format_vulnerability(vulnerability, image)
            {
              'category' => 'container_scanning',
              'message' => message(vulnerability),
              'description' => description(vulnerability),
              'cve' => vulnerability['vulnerability'],
              'severity' => translate_severity(vulnerability['severity']),
              'solution' => solution(vulnerability),
              'confidence' => 'Medium',
              'location' => {
                'image' => image,
                'operating_system' => vulnerability["namespace"],
                'dependency' => {
                  'package' => {
                    'name' => vulnerability["featurename"]
                  },
                  'version' => vulnerability["featureversion"]
                }
              },
              'scanner' => { 'id' => 'clair', 'name' => 'Clair' },
              'identifiers' => [
                {
                  'type' => 'cve',
                  'name' => vulnerability['vulnerability'],
                  'value' => vulnerability['vulnerability'],
                  'url' => vulnerability['link']
                }
              ],
              'links' => [{ 'url' => vulnerability['link'] }]
            }
          end

          def translate_severity(severity)
            case severity
            when 'Negligible'
              'low'
            when 'Unknown', 'Low', 'Medium', 'High', 'Critical'
              severity.downcase
            when 'Defcon1'
              'critical'
            else
              safe_severity = ERB::Util.html_escape(severity)
              raise SecurityReportParserError, "Unknown severity in container scanning report: #{safe_severity}"
            end
          end

          def message(vulnerability)
            format(
              vulnerability,
              %w[vulnerability featurename] =>
                '%{vulnerability} in %{featurename}',
              'vulnerability' =>
                '%{vulnerability}'
            )
          end

          def description(vulnerability)
            format(
              vulnerability,
              'description' =>
                '%{description}',
              %w[featurename featureversion] =>
                '%{featurename}:%{featureversion} is affected by %{vulnerability}',
              'featurename' =>
                '%{featurename} is affected by %{vulnerability}',
              'namespace' =>
                '%{namespace} is affected by %{vulnerability}'
            )
          end

          def solution(vulnerability)
            format(
              vulnerability,
              %w[fixedby featurename featureversion] =>
                'Upgrade %{featurename} from %{featureversion} to %{fixedby}',
              %w[fixedby featurename] =>
                'Upgrade %{featurename} to %{fixedby}',
              'fixedby' =>
                'Upgrade to %{fixedby}'
            )
          end

          def format(vulnerability, definitions)
            definitions.each do |keys, value|
              if vulnerability.values_at(*Array(keys)).all?(&:present?)
                return value % vulnerability.symbolize_keys
              end
            end

            nil
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
