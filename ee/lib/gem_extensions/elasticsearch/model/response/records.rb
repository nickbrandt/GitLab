# frozen_string_literal: true
module GemExtensions
  module Elasticsearch
    module Model
      module Response
        # We need to change the ID used to recover items from the database.
        # Originally elasticsearch-model uses `_id`, but we need to use the `id` field
        module Records
          def ids
            response.response['hits']['hits'].map { |hit| hit['_source']['id'] }
          end
        end
      end
    end
  end
end
