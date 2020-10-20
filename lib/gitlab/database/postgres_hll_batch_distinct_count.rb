# frozen_string_literal: true

module Gitlab
  module Database
    module PostgresHllBatchDistinctCount
      def batch_distinct_count(relation, column = nil, batch_size: nil, start: nil, finish: nil)
        PostgresHllBatchDistinctCounter.new(relation, column: column).count(batch_size: batch_size, start: start, finish: finish)
      end

      class << self
        include PostgresHllBatchDistinctCount
      end
    end

    class PostgresHllBatchDistinctCounter
      FALLBACK = -1
      MIN_REQUIRED_BATCH_SIZE = 1_250
      MAX_ALLOWED_LOOPS = 10_000
      SLEEP_TIME_IN_SECONDS = 0.01 # 10 msec sleep

      # Each query should take < 500ms https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22705
      DEFAULT_BATCH_SIZE = 100_000

      BIT_31_MASK = "B'0#{'1' * 31}'"
      BIT_9_MASK = "B'#{'0' * 23}#{'1' * 9}'"

      # source_query:
      # SELECT CAST(('X' || md5(CAST(%{column} as text))) as bit(32)) attr_hash_32_bits
      # FROM %{relation}
      # WHERE %{pkey} >= %{batch_start} AND %{pkey} < %{batch_end}
      #   AND %{column} IS NOT NULL
      BUCKETED_DATA_SQL = <<~SQL
        WITH hashed_attributes AS (%{source_query})
        SELECT (attr_hash_32_bits & #{BIT_9_MASK})::int AS bucket_num,
          (31 - floor(log(2, min((attr_hash_32_bits & #{BIT_31_MASK})::int))))::int as bucket_hash
        FROM hashed_attributes
        GROUP BY 1 ORDER BY 1
      SQL

      def initialize(relation, column: nil, operation_args: nil)
        @relation = relation
        @column = column || relation.primary_key
        @operation_args = operation_args
      end

      def unwanted_configuration?(finish, batch_size, start)
        batch_size <= MIN_REQUIRED_BATCH_SIZE ||
          (finish - start) / batch_size >= MAX_ALLOWED_LOOPS ||
          start > finish
      end

      def count(batch_size: nil, start: nil, finish: nil)
        raise 'BatchCount can not be run inside a transaction' if ActiveRecord::Base.connection.transaction_open?

        batch_size ||= DEFAULT_BATCH_SIZE

        start = actual_start(start)
        finish = actual_finish(finish)

        raise "Batch counting expects positive values only for #{@column}" if start < 0 || finish < 0
        return FALLBACK if unwanted_configuration?(finish, batch_size, start)

        batch_start = start
        hll_blob = {}

        while batch_start <= finish
          begin
            hll_blob.merge!(hll_blob_for_batch(batch_start, batch_start + batch_size)) {|_key, old, new| new > old ? new : old }
            batch_start += batch_size
          rescue ActiveRecord::QueryCanceled
            # retry with a safe batch size & warmer cache
            if batch_size >= 2 * MIN_REQUIRED_BATCH_SIZE
              batch_size /= 2
            else
              return FALLBACK
            end
          end
          sleep(SLEEP_TIME_IN_SECONDS)
        end

        estimate_cardinality(hll_blob)
      end

      private

      def estimate_cardinality(hll_blob)
        num_zero_buckets = 512 - hll_blob.size

        num_uniques = (
          ((512**2) * (0.7213 / (1 + 1.079 / 512))) /
            (num_zero_buckets + hll_blob.values.sum { |bucket_hash, _| 2**(-1 * bucket_hash)} )
        ).to_i

        if num_zero_buckets > 0 && num_uniques < 2.5 * 512
          ((0.7213 / (1 + 1.079 / 512)) * (512 *
            Math.log2(512.0 / num_zero_buckets)))
        else
          num_uniques
        end
      end

      def hll_blob_for_batch(start, finish)
        @relation
          .connection
          .execute(BUCKETED_DATA_SQL % { source_query: source_query(start, finish) })
          .map(&:values)
          .to_h
      end

      # SELECT CAST(('X' || md5(CAST(%{column} as text))) as bit(32)) attr_hash_32_bits
      # FROM %{relation}
      # WHERE %{pkey} >= %{batch_start} AND %{pkey} < %{batch_end}
      #   AND %{column} IS NOT NULL
      def source_query(start, finish)
        col_as_arel = @column.is_a?(Arel::Attributes::Attribute) ? @column : Arel.sql(@column.to_s)
        col_as_text = Arel::Nodes::NamedFunction.new('CAST', [col_as_arel.as('text')])
        md5_of_col = Arel::Nodes::NamedFunction.new('md5', [col_as_text])
        md5_as_hex = Arel::Nodes::Concat.new(Arel.sql("'X'"), md5_of_col)
        bits = Arel::Nodes::NamedFunction.new('CAST', [md5_as_hex.as('bit(32)')])

        @relation
          .where(@relation.primary_key => (start...finish))
          .where(col_as_arel.not_eq(nil))
          .select(bits.as('attr_hash_32_bits')).to_sql
      end

      def actual_start(start)
        start || @relation.unscope(:group, :having).minimum(@relation.primary_key) || 0
      end

      def actual_finish(finish)
        finish || @relation.unscope(:group, :having).maximum(@relation.primary_key) || 0
      end
    end
  end
end
