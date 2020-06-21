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
      LIMIT = 10_000

      class << self
        def logger
          ::Gitlab::Elasticsearch::Logger.build
        end
      end

      class InitialProcessor < self
        REDIS_SET_KEY = 'elastic:bulk:initial:0:zset'
        REDIS_SCORE_KEY = 'elastic:bulk:initial:0:score'

        INDEXED_ASSOCIATIONS = {
          issues:         ->(project) { project.issues },
          merge_requests: ->(project) { project.merge_requests },
          snippets:       ->(project) { project.snippets },
          notes:          ->(project) { project.notes.searchable },
          milestones:     ->(project) { project.milestones }
        }.freeze

        def self.backfill_projects!(*projects)
          raise ArgumentError, "Only Projects can be backfilled." unless projects.all? { |p| p.is_a?(Project) }

          process_async(*projects)

          # Index the repository & wiki
          Indexer::InitialProcessor.process_async(*projects)
          WikiIndexer::InitialProcessor.process_async(*projects)

          INDEXED_ASSOCIATIONS.each do |_, association|
            projects.each do |project|
              association.call(project).find_in_batches { |batch| process_async(*batch) }
            end
          end
        end

        extend ::Elastic::ProcessBookkeepingService::Processor
      end

      class IncrementalProcessor < self
        REDIS_SET_KEY = 'elastic:bulk:updates:0:zset'
        REDIS_SCORE_KEY = 'elastic:bulk:updates:0:score'

        extend ::Elastic::ProcessBookkeepingService::Processor
      end

      include ::Elasticsearch::Model::Client::ClassMethods

      attr_reader :failures

      def initialize
        @body = []
        @body_size_bytes = 0
        @failures = []
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

        self
      end

      def flush
        send_bulk.failures
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
      end

      def delete(ref)
        proxy = ref.klass.__elasticsearch__
        op = build_op(ref, proxy)

        submit(delete: op)
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
        jsons = hashes.map(&:to_json)
        bytesize = calculate_bytesize(jsons)

        send_bulk if will_exceed_bulk_limit?(bytesize)

        body.concat(jsons)
        @body_size_bytes += bytesize
      end

      def calculate_bytesize(jsons)
        jsons.reduce(0) do |sum, json|
          sum + json.bytesize + 2 # Account for newlines
        end
      end

      def will_exceed_bulk_limit?(bytesize)
        body_size_bytes + bytesize > bulk_limit_bytes
      end

      def send_bulk
        return self if body.empty?

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

      def logger
        self.class.logger
      end
    end
  end
end
