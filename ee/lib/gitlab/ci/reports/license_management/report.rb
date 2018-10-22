# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module LicenseManagement
        class Report
          def initialize
            @found_licenses = {}
          end

          def licenses
            @found_licenses.values
          end

          def license_names
            @found_licenses.values.map(&:name)
          end

          def add_dependency(license_name, dependency_name)
            key = license_name.upcase
            @found_licenses[key] ||= ::Gitlab::Ci::Reports::LicenseManagement::License.new(license_name)
            @found_licenses[key].add_dependency(dependency_name)
          end
        end
      end
    end
  end
end
