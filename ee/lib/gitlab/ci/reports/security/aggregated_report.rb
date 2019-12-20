# frozen_string_literal: true

# Used to represent combined Security Reports. This is typically done for vulnerability deduplication purposes.

module Gitlab
  module Ci
    module Reports
      module Security
        class AggregatedReport
          attr_reader :occurrences

          def initialize(reports, occurrences)
            @reports = reports
            @occurrences = occurrences
          end

          def created_at
            @reports.map(&:created_at).compact.min
          end
        end
      end
    end
  end
end
