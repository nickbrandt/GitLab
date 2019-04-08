# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        module Locations
          class ContainerScanning < Base
            attr_reader :image
            attr_reader :operating_system
            attr_reader :package_name
            attr_reader :package_version

            def initialize(image:, operating_system:, package_name: nil, package_version: nil)
              @image = image
              @operating_system = operating_system
              @package_name = package_name
              @package_version = package_version
            end

            private

            def fingerprint_data
              "#{operating_system}:#{package_name}"
            end
          end
        end
      end
    end
  end
end
