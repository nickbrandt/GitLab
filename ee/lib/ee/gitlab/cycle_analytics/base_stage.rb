# frozen_string_literal: true

module EE
  module Gitlab
    module CycleAnalytics
      module BaseStage
        def data_for_duration_chart
          ::Gitlab::CycleAnalytics::DurationChartDataFetcher.new(self).fetch
        end
      end
    end
  end
end
