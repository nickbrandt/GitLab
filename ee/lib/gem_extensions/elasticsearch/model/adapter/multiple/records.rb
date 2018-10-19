# frozen_string_literal: true
module GemExtensions
  module Elasticsearch
    module Model
      module Adapter
        module Multiple
          # We need to change the ID used to recover items from the database.
          # Originally elasticsearch-model uses `_id`, but we need to use the `id` field
          module Records
            def records
              records_by_type = __records_by_type

              records = response.response["hits"]["hits"].map do |hit|
                records_by_type[__type_for_hit(hit)][hit[:_source][:id].to_s]
              end

              records.compact
            end

            def __type_for_hit(hit)
              @@__types ||= {} # rubocop:disable Style/ClassVars

              @@__types[ "#{hit[:_index]}::#{hit[:_source][:type]}" ] ||= begin
                ::Elasticsearch::Model::Registry.all.detect do |model|
                  model.index_name == hit[:_index] && model.es_type == hit[:_source][:type]
                end
              end
            end

            def __ids_by_type
              ids_by_type = {}

              response.response["hits"]["hits"].each do |hit|
                type = __type_for_hit(hit)
                ids_by_type[type] ||= []
                ids_by_type[type] << hit[:_source][:id]
              end
              ids_by_type
            end
          end
        end
      end
    end
  end
end
