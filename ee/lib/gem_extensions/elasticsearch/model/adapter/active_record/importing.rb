# frozen_string_literal: true
module GemExtensions
  module Elasticsearch
    module Model
      module Adapter
        module ActiveRecord
          module Importing
            def __transform
              lambda { |model| { index: { _id: model.id, data: model.__elasticsearch__.version(version_namespace).as_indexed_json } } }
            end
          end
        end
      end
    end
  end
end
