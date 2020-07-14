# frozen_string_literal: true

module Gitlab
  module Analytics
    module Reports
      class ReportBuilder
        def self.build(raw_report)
          series = raw_report[:chart][:series].map { |id, series| build_series(series.merge(id: id)) }

          chart = Chart.new(type: raw_report[:chart][:type], series: series)

          Report.new(
            id: raw_report[:id],
            title: raw_report[:title],
            chart: chart
          )
        end

        def self.build_series(raw_series)
          Series.new(
            id: raw_series[:id],
            title: raw_series[:title],
            data_retrieval_options: {
              data_retrieval: raw_series[:data_retrieval]
            }.merge(raw_series[:data_retrieval_options])
          )
        end

        private_class_method :build_series
      end
    end
  end
end
