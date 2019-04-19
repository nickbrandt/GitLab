# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class ReportsDiff
          attr_accessor :added, :existing, :fixed

          def initialize
            @added = []
            @existing = []
            @fixed = []
          end
        end
      end
    end
  end
end
