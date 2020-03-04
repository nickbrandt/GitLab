# frozen_string_literal: true

module Ci
  class DailyReportResultService
    def execute(pipeline)
      DailyReportResult.store_coverage(pipeline)
    end
  end
end
