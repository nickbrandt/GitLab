# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class Dast < Common
          FORMAT_VERSION = '2.0'.freeze

          protected

          def parse_report(json_data)
            report = super

            format_report(report)
          end

          private

          def format_report(data)
            {
              'vulnerabilities' => extract_vulnerabilities_from(data),
              'version' => FORMAT_VERSION
            }
          end

          def extract_vulnerabilities_from(data)
            site = data['site'].first
            results = []

            if site
              host = site['@name']

              site['alerts'].each do |vulnerability|
                results += flatten_vulnerabilities(vulnerability, host)
              end
            end

            results
          end

          def flatten_vulnerabilities(vulnerability, host)
            vulnerability['instances'].map do |instance|
              Formatters::Dast.new(vulnerability).format(instance, host)
            end
          end

          def create_location(location_data)
            ::Gitlab::Ci::Reports::Security::Locations::Dast.new(
              hostname: location_data['hostname'],
              method_name: location_data['method'],
              param: location_data['param'],
              path: location_data['path'])
          end
        end
      end
    end
  end
end
