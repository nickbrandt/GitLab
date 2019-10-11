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

          def hash
            name.hash
          end

          def eql?(other)
            self.name == other.name
          end
        end
      end
    end
  end
end
