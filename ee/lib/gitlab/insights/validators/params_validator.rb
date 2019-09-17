# frozen_string_literal: true

module Gitlab
  module Insights
    module Validators
      class ParamsValidator
        ParamsValidatorError = Class.new(StandardError)
        InvalidTypeError = Class.new(ParamsValidatorError)

        SUPPORTER_TYPES = %w[bar line stacked-bar pie].freeze

        def initialize(params)
          @params = params
        end

        def validate!
          unless SUPPORTER_TYPES.include?(params[:type])
            raise InvalidTypeError, "Invalid `:type`: `#{params[:type]}`. Allowed values are #{SUPPORTER_TYPES}!"
          end
        end

        private

        attr_reader :params
      end
    end
  end
end
