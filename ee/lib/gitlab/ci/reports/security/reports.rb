# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Reports
          attr_reader :reports

          def initialize
            @reports = {}
          end

          def get_report(report_type)
            reports[report_type] ||= Report.new(report_type)
          end
        end
      end
    end
  end
end
