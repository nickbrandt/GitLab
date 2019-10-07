# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module LicenseScanning
        class Dependency
          attr_reader :name

          def initialize(name)
            @name = name
          end
        end
      end
    end
  end
end
