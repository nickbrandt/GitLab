# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module LicenseScanning
        class License
          attr_reader :name, :url, :count

          def initialize(name, count, url)
            @name = name
            @count = count
            @url = url
            @dependencies = Set.new
          end

          def add_dependency(name)
            @dependencies.add(::Gitlab::Ci::Reports::LicenseScanning::Dependency.new(name))
          end

          def dependencies
            @dependencies.to_a
          end
        end
      end
    end
  end
end
