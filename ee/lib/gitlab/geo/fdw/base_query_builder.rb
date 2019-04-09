# frozen_string_literal: true

module Gitlab
  module Geo
    class Fdw
      class BaseQueryBuilder < SimpleDelegator
        def initialize(query = nil)
          @query = query || base
          super(query)
        end

        private

        attr_reader :query

        def base
          raise NotImplementedError
        end

        def reflect(query)
          self.class.new(query)
        end
      end
    end
  end
end
