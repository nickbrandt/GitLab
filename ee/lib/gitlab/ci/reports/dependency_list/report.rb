# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module DependencyList
        class Report
          attr_accessor :dependencies

          def initialize
            @dependencies = []
          end

          def add_dependency(dependency)
            dependencies << dependency
          end

          def apply_license(license)
            dependencies.each do |dependency|
              next unless license.dependencies.find { |license_dependency| license_dependency.name == dependency[:name] }
              next if dependency[:licenses].find { |license_hash| license_hash[:name] == license.name }

              dependency[:licenses].push(name: license.name, url: license.url)
            end
          end

          def dependencies_with_licenses
            dependencies.select { |dependency| dependency[:licenses].any? }
          end
        end
      end
    end
  end
end
