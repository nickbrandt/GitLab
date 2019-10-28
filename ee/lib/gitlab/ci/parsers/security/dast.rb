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
              'vulnerabilities' => extract_vulnerabilities_from(Array.wrap(data['site'])),
              'version' => FORMAT_VERSION
            }
          end

          # Log messages to be added here to track usage of legacy reports,
          # parsing failures and any other scenarios: https://gitlab.com/gitlab-org/gitlab/issues/34668
          def extract_vulnerabilities_from(sites = [])
            return [] if sites.empty?

            vulnerabilities = []

            sites.each do |site|
              site_report = Hash(site)
              next if site_report.blank?

              # If host is blank for legacy reports
              host = site_report['@name']

              site_report['alerts'].each do |vulnerability|
                vulnerabilities += flatten_vulnerabilities(vulnerability, host)
              end
            end

            vulnerabilities
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
