# frozen_string_literal: true

module Gitlab
  module Elastic
    # Accumulate records and submit to elasticsearch in bulk, respecting limits
    # on request size.
    #
    # Call +process+ to accumulate records in memory, submitting bulk requests
    # when the bulk limits are reached.
    #
    # Once finished, call +flush+. Any errors accumulated earlier will be
    # reported by this call.
    #
    # BulkIndexer is not safe for concurrent use.
    class BulkIndexer
      include ::Elasticsearch::Model::Client::ClassMethods

      attr_reader :logger, :failures

      def initialize(logger:)
        @body = []
        @body_size_bytes = 0
        @failures = []
        @logger = logger
        @ref_cache = []
      end

      # Adds or removes a document in elasticsearch, depending on whether the
      # database record it refers to can be found
      def process(ref)
        ref_cache << ref

        if ref.database_record
          index(ref)
        else
          delete(ref)
        end
      end

      def flush
        maybe_send_bulk(force: true).failures
      end

      private

      def reset!
        @body = []
        @body_size_bytes = 0
        @ref_cache = []
      end

      attr_reader :body, :body_size_bytes, :ref_cache

      def index(ref)
        proxy = ref.database_record.__elasticsearch__
        op = build_op(ref, proxy)

        submit({ index: op }, proxy.as_indexed_json)

        maybe_send_bulk
      end

      def delete(ref)
        proxy = ref.klass.__elasticsearch__
        op = build_op(ref, proxy)

        submit(delete: op)

        maybe_send_bulk
      end

      def build_op(ref, proxy)
        op = {
          _index: proxy.index_name,
          _type: proxy.document_type,
          _id: ref.es_id
        }

        op[:routing] = ref.es_parent if ref.es_parent # blank for projects

        op
      end

      def bulk_limit_bytes
        Gitlab::CurrentSettings.elasticsearch_max_bulk_size_mb.megabytes
      end

      def submit(*hashes)
        hashes.each do |hash|
          text = hash.to_json

          body.push(text)
          @body_size_bytes += text.bytesize + 2 # Account for newlines
        end
      end

      def maybe_send_bulk(force: false)
        return self if body.empty?
        return self if body_size_bytes < bulk_limit_bytes && !force

        failed_refs = try_send_bulk

        logger.info(
          message: 'bulk_submitted',
          body_size_bytes: body_size_bytes,
          bulk_count: ref_cache.count,
          errors_count: failed_refs.count
        )

        failures.push(*failed_refs)

        reset!

        self
      end

      def try_send_bulk
        process_errors(client.bulk(body: body))
      rescue => err
        # If an exception is raised, treat the entire bulk as failed
        logger.error(message: 'bulk_exception', error_class: err.class.to_s, error_message: err.message)

        ref_cache
      end

      def process_errors(result)
        return [] unless result['errors']

        out = []

        # Items in the response have the same order as items in the request.
        #
        # Example succces: {"index": {"result": "created", "status": 201}}
        # Example failure: {"index": {"error": {...}, "status": 400}}
        result['items'].each_with_index do |item, i|
          op = item['index'] || item['delete']

          if op.nil? || op['error']
            logger.warn(message: 'bulk_error', item: item)
            out << ref_cache[i]
          end
        end

        out
      end
    end
  end
end
