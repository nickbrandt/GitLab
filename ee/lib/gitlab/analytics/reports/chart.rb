# frozen_string_literal: true

module Gitlab
  module Analytics
    module Reports
      class Chart
        attr_reader :type, :series

        def initialize(type:, series:)
          @type = type
          @series = series
        end
      end
    end
  end
end
