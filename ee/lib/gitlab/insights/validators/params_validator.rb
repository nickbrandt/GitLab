# frozen_string_literal: true

module Gitlab
  module Insights
    module Validators
      class ParamsValidator
        ParamsValidatorError = Class.new(StandardError)
        InvalidChartTypeError = Class.new(ParamsValidatorError)

        SUPPORTER_CHART_TYPES = %w[bar line stacked-bar pie].freeze

        def initialize(params)
          @params = params
        end

        def validate!
          unless SUPPORTER_CHART_TYPES.include?(params[:chart_type])
            raise InvalidChartTypeError, "Invalid `:chart_type`: `#{params[:chart_type]}`. Allowed values are #{SUPPORTER_CHART_TYPES}!"
          end
        end

        private

        attr_reader :params
      end
    end
  end
end
