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
              next unless dependency[:name] == license[:dependency][:name]

              dependency[:licenses] << license[:license]
            end
          end
        end
      end
    end
  end
end
