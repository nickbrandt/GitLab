# frozen_string_literal: true

module GemExtensions
  module Elasticsearch
    module Model
      module Response
        module Results
          # Handle ES7 API where total is returned as an object. This
          # change is taken from the V7 gem
          # https://github.com/elastic/elasticsearch-rails/commit/9c40f630e1b549f0b7889fe33dcd826b485af6fc
          # and can be removed when we upgrade the gem to V7
          def total
            if response.response['hits']['total'].respond_to?(:keys)
              response.response['hits']['total']['value']
            else
              response.response['hits']['total']
            end
          end
        end
      end
    end
  end
end
