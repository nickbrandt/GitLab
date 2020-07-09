# frozen_string_literal: true

module Gitlab
  module Analytics
    module Reports
      class SeriesDataLoader
        def initialize(series:, params: {})
          @series = series
          @params = params
        end

        def execute
          execute_insights_query
        end

        private

        attr_reader :series, :params

        def execute_insights_query
          data_retrieval_options = series.data_retrieval_options.dup

          raise 'unknown method' if data_retrieval_options.delete(:data_retrieval) != 'Insights'

          finder = Gitlab::Insights::Finders::IssuableFinder.new(params[:parent], params[:current_user], query: data_retrieval_options)

          Gitlab::Insights::Reducers::CountPerPeriodReducer.reduce(finder.find, period: data_retrieval_options[:group_by], period_limit: finder.period_limit)
        end
      end
    end
  end
end
