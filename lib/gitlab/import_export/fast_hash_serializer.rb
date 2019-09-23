# frozen_string_literal: true

# ActiveModel::Serialization (https://github.com/rails/rails/blob/v5.0.7/activemodel/lib/active_model/serialization.rb#L184)
# is simple in that it recursively calls `as_json` on each object to
# serialize everything. However, for a model like a Project, this can
# generate a query for every single association, which can add up to tens
# of thousands of queries and lead to memory bloat.
#
# To improve this, we can do several things:

# 1. Use the option tree in http://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html
#    to generate the necessary preload clauses.
#
# 2. We observe that a single project has many issues, merge requests,
#    etc. Instead of serializing everything at once, which could lead to
#    database timeouts and high memory usage, we take each top-level
#    association and serialize the data in batches.
#
#  For example, we serialize the first 100 issues and preload all of
#  their associated events, notes, etc. before moving onto the next
#  batch. When we're done, we serialize merge requests in the same way.
#  We repeat this pattern for the remaining associations specified in
#  import_export.yml.
module Gitlab
  module ImportExport
    class FastHashSerializer
      attr_reader :subject, :tree

      # Usage of this class results in delayed
      # serialization of relation. The serialization
      # will be triggered when the `JSON.generate`
      # is exected.
      #
      # This class uses memory-optimised, lazily
      # initialised, fast to recycle relation
      # serialization.
      #
      # The `JSON.generate` does use `#to_json`,
      # that returns raw JSON content that is written
      # directly to file.
      class JSONBatchRelation
        def initialize(relation, options, preloads)
          @relation = relation
          @options = options
          @preloads = preloads
        end

        def to_json(options = {})
          result = +''

          batch = @relation
          batch = batch.preload(@preloads) if @preloads
          batch.each do |item|
            result.concat(",") unless result.empty?
            result.concat(item.to_json(@options))
          end

          result
        end

        def as_json(*)
          raise NotImplementedError
        end
      end

      BATCH_SIZE = 100

      def initialize(subject, tree, additional_attributes: {}, batch_size: BATCH_SIZE)
        @subject = subject
        @batch_size = batch_size
        @tree = tree
        @additional_attributes = additional_attributes
      end

      # Serializes the subject into JSON for the given option tree
      def execute
        serialized_hash = simple_serialize.merge(serialize_includes)

        merge_additional_attributes!(serialized_hash)

        RelationRenameService.add_new_associations(serialized_hash) if subject.is_a?(Project)

        JSON.generate(serialized_hash)
      end

      private

      def simple_serialize
        subject.as_json(
          tree.merge(include: nil, preloads: nil))
      end

      def serialize_includes
        return {} unless includes

        includes
          .map(&method(:serialize_include_definition))
          .compact
          .to_h
      end

      # definition:
      # { labels: { includes: ... } }
      def serialize_include_definition(definition)
        raise ArgumentError, 'definition needs to be Hash' unless definition.is_a?(Hash)
        raise ArgumentError, 'definition needs to have exactly one Hash element' unless definition.one?

        key = definition.first.first
        options = definition.first.second

        record = subject.public_send(key) # rubocop: disable GitlabSecurity/PublicSend
        return unless record

        serialized_record = serialize_record(key, record, options)
        return unless serialized_record

        # `#as_json` always returns keys as `strings`
        [key.to_s, serialized_record]
      end

      def serialize_record(key, record, options)
        unless record.respond_to?(:as_json)
          raise "Invalid type of #{key} is #{record.class}"
        end

        # no has-many relation
        unless record.is_a?(ActiveRecord::Relation)
          return record.as_json(options)
        end

        data = []

        record.in_batches(of: @batch_size) do |batch| # rubocop:disable Cop/InBatches
          data.append(JSONBatchRelation.new(batch, options, preloads[key]))
        end

        data
      end

      def merge_additional_attributes!(serialized_hash)
        serialized_hash.deep_merge!(@additional_attributes) do |key, this_val, other_val|
          # when serializing Project, we need to append `group_members` from `additional_attributes`, not to replace
          if this_val.is_a?(Array) && other_val.is_a?(Array)
            this_val + other_val
          else
            other_val
          end
        end
      end

      def includes
        tree[:include]
      end

      def preloads
        tree[:preload]
      end
    end
  end
end
