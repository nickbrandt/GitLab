# frozen_string_literal: true

module Gitlab
  module Analytics
    module Reports
      class Report
        attr_reader :id, :title, :chart

        def initialize(id:, title:, chart:)
          @id = id
          @title = title
          @chart = chart
        end

        def find_series_by_id(series_id)
          chart.series.find { |series| series.id.to_s.eql?(series_id.to_s) }
        end
      end
    end
  end
end
