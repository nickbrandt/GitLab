# frozen_string_literal: true

module Gitlab
  module ImportExport
    module JSON
      class StreamingSerializer
        include Gitlab::ImportExport::CommandLineUtil

        attr_reader :overrides
        attr_reader :additional_relations

        BATCH_SIZE = 100

        class Raw < String
          def to_json(*_args)
            to_s
          end
        end

        def initialize(exportable, relations_schema, json_writer)
          @exportable = exportable
          @relations_schema = relations_schema
          @overrides = {}
          @json_writer = json_writer
          @additional_relations = {}
        end

        def execute
          serialize_root

          includes.each do |relation_definition|
            serialize_relation(relation_definition)
          end
        end

        private

        attr_reader :json_writer, :relations_schema, :exportable

        def serialize_root
          attributes = exportable.as_json(
            relations_schema.merge(include: nil, preloads: nil))

          data = attributes.merge(overrides)

          json_writer.set(data)
        end

        def serialize_relation(definition)
          raise ArgumentError, 'definition needs to be Hash' unless definition.is_a?(Hash)
          raise ArgumentError, 'definition needs to have exactly one Hash element' unless definition.one?

          key = definition.first.first
          options = definition.first.second

          record = exportable.public_send(key) # rubocop: disable GitlabSecurity/PublicSend

          if record.is_a?(ActiveRecord::Relation)
            serialize_many_relations(key, record, options)
          else
            serialize_single_relation(key, record, options)
          end
        end

        def serialize_many_relations(key, record, options)
          key_preloads = preloads&.dig(key)

          record.in_batches(of: BATCH_SIZE) do |batch| # rubocop:disable Cop/InBatches
            batch = batch.preload(key_preloads) if key_preloads

            batch.each do |item|
              item = Raw.new(item.to_json(options))

              json_writer.append(key, item)
            end
          end

          additional_relations[key].to_a.each do |item|
            item = Raw.new(item.to_json(options))

            json_writer.append(key, item)
          end
        end

        def serialize_single_relation(key, record, options)
          json = Raw.new(record.to_json(options))

          json_writer.write(key, json)
        end

        def includes
          relations_schema[:include]
        end

        def preloads
          relations_schema[:preload]
        end
      end
    end
  end
end
