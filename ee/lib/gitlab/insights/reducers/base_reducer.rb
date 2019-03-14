# frozen_string_literal: true

module Gitlab
  module Insights
    module Reducers
      class BaseReducer
        BaseReducerError = Class.new(StandardError)

        def self.reduce(issuables, **args)
          new(issuables, **args).reduce
        end

        def initialize(issuables)
          @issuables = issuables
        end
        private_class_method :new

        # Should return an insights hash.
        def reduce
          raise NotImplementedError
        end

        private

        attr_reader :issuables
      end
    end
  end
end
