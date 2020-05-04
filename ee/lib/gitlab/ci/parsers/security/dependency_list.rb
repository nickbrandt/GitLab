# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class DependencyList
          def initialize(project, sha)
            @formatter = Formatters::DependencyList.new(project, sha)
          end

          def parse!(json_data, report)
            report_data = Gitlab::Json.parse(json_data)
            report_data.fetch('dependency_files', []).each do |file|
              file['dependencies'].each do |dependency|
                report.add_dependency(formatter.format(dependency,
                                                       file['package_manager'],
                                                       file['path'],
                                                       report_data['vulnerabilities']))
              end
            end
          end

          def parse_licenses!(json_data, report)
            license_report = ::Gitlab::Ci::Reports::LicenseScanning::Report.parse_from(json_data)
            license_report.licenses.each do |license|
              report.apply_license(license)
            end
          end

          private

          attr_reader :formatter
        end
      end
    end
  end
end
