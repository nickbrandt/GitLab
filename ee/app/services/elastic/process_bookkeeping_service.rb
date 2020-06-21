# frozen_string_literal: true

module Elastic
  class ProcessBookkeepingService
    # This module ensures the compatibilty for the processor class
    # by making sure it exposes the proper keys
    module Processor
      KEYSET = [
        :REDIS_SET_KEY,
        :REDIS_SCORE_KEY
      ].freeze

      @classes = Set.new
      @queues = Hash.new { |h, k| h[k] = Set.new }

      def self.each
        @classes.each { |cls| yield cls }
      end

      def self.ensure_const!(cls, const)
        return cls.const_get(const, true) if cls.const_defined?(const) # rubocop:disable Gitlab/ConstGetInheritFalse

        raise StandardError.new("#{cls} cannot be used as a Processor: #{const} is not defined.")
      end

      # Ensure each Processor exposes a unique queue.
      def self.extended(cls)
        @classes << cls

        KEYSET.each do |k|
          queue_name = ensure_const!(cls, k)

          raise StandardError.new("#{cls} redefine queue #{queue_name}") if @queues[k].include?(queue_name)

          @queues[k] << queue_name
        end

        # ensure LIMIT
        ensure_const!(cls, :LIMIT)
      end

      def self.queues
        @queues.dup
      end

      def process(*refs)
        raise NotImplementedError
      end

      def flush
        raise NotImplementedError
      end

      def process_async(*items)
        ProcessBookkeepingService.track!(*items, processor: self)
      end

      def service
        ProcessBookkeepingService.new(new)
      end
    end

    class << self
      # Add some records to the processing queue. Items must be serializable to
      # a Gitlab::Elastic::DocumentReference
      def track!(*items, processor:)
        raise StandardError, "#{processor} doesn't implement #{Processor}" unless processor.is_a? Processor
        return true if items.empty?

        refs = items.map do |item|
          ::Gitlab::Elastic::DocumentReference.serialize(item)
        end

        with_redis do |redis|
          scored_refs(*refs, processor: processor) do |group|
            logger.debug(class: self.name,
                         redis_set: processor::REDIS_SET_KEY,
                         message: 'track_items',
                         count: group.count,
                         tracked_items_encoded: group.to_json)

            # We don't update existing entries so that the order of
            # insertion is guaranteed (FIFO).
            redis.zadd(processor::REDIS_SET_KEY, group, nx: true)
          end
        end

        true
      end

      def scored_refs(*refs, processor:, &blk)
        with_score_redis do |redis|
          # Efficiently generate a guaranteed-unique score for each item
          max = redis.incrby(processor::REDIS_SCORE_KEY, refs.size)
          min = (max - refs.size) + 1

          (min..max).zip(refs).each_slice(1000, &blk)
        end
      end

      def queue_size(processor:)
        with_redis { |redis| redis.zcard(processor::REDIS_SET_KEY) }
      end

      def clear_tracking!(processor:)
        with_redis { |redis| redis.del(processor::REDIS_SET_KEY, processor::REDIS_SCORE_KEY) }
      end

      def logger
        # build already caches the logger via request store
        ::Gitlab::Elasticsearch::Logger.build
      end

      def with_redis(&blk)
        ::Gitlab::Redis::SharedState.with(&blk) # rubocop:disable CodeReuse/ActiveRecord
      end

      # We need to use a different connection outside of the pool
      # for operations that can't run in a transaction, like assigning
      # the score to the DocumentReferences
      def with_score_redis(&blk)
        yield ::Redis.new(Gitlab::Redis::SharedState.params)
      end
    end

    attr_reader :processor

    def initialize(processor)
      raise StandardError.new(processor) unless processor.class.is_a? Processor

      @processor = processor
    end

    def execute
      self.class.with_redis { |redis| execute_with_redis(redis) }
    end

    private

    def track!(*items)
      self.class.track!(*items, processor: @processor.class)
    end

    def execute_with_redis(redis)
      start_time = Time.current

      specs = redis.zrangebyscore(processor.class::REDIS_SET_KEY,
                                  '-inf', '+inf',
                                  limit: [0, processor.class::LIMIT],
                                  with_scores: true)
      return 0 if specs.empty?

      first_score = specs.first.last
      last_score = specs.last.last

      logger.info(
        message: 'bulk_indexing_start',
        records_count: specs.count,
        first_score: first_score,
        last_score: last_score
      )

      refs = deserialize_all(specs)
      refs.preload_database_records!

      # Run the processor on the batch, returning the failures
      refs.each { |ref| processor.process(ref) }
      failures = processor.flush

      redis.multi do |multi|
        # Remove all the successes
        multi.zremrangebyscore(processor.class::REDIS_SET_KEY, first_score, last_score)

        # Re-enqueue any failures so they are retried
        track!(*failures)
      end

      records_count = specs.count

      logger.info(
        message: 'bulk_indexing_end',
        records_count: records_count,
        failures_count: failures.count,
        first_score: first_score,
        last_score: last_score,
        bulk_execution_duration_s: Time.current - start_time
      )

      records_count
    end

    def deserialize_all(specs)
      refs = ::Gitlab::Elastic::DocumentReference::Collection.new

      specs.each do |spec, _|
        refs.deserialize_and_add(spec)
      rescue ::Gitlab::Elastic::DocumentReference::InvalidError => err
        logger.warn(
          message: 'submit_document_failed',
          reference: spec,
          error_class: err.class.to_s,
          error_message: err.message
        )
      end

      refs
    end

    def logger
      self.class.logger
    end
  end
end
