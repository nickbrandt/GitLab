# frozen_string_literal: true

module Issue
  class RebalancingService < Issues::BaseService
    MAX_ISSUE_COUNT = 100_000
    TooManyIssues = Class.new(StandardError)

    attr_reader :issue

    def initialize(issue)
      @issue = issue
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def execute
      base = Issue.relative_positioning_query_base(issue)

      n = base.count

      if n > MAX_ISSUE_COUNT
        raise TooManyIssues, "#{n} issues"
      end

      gaps = n - 1
      gap_size = 0
      ratio = 0.5

      while gap_size < RelativePositioning::MIN_GAP && ratio < 1
        gap_size = (ratio * Gitlab::Database::MAX_INT_VALUE) / (gaps / 2)
        ratio += 0.1
      end

      # If there are 4 billion issues, then we cannot rebalance them
      if gap_size < RelativePositioning::MIN_GAP
        raise RelativePositioning::NoSpaceLeft
      end

      start = 0 - (gaps / 2) * gap_size

      indexed = base.reorder(:relative_position, :id).pluck(:id).each_with_index

      indexed.each_slice(500) do |pairs|
        values = pairs.map do |id, index|
          "(#{id}, #{start + (index * gap_size)})"
        end.join(', ')

        Issue.connection.exec_query(<<~SQL, "rebalance issue positions")
          WITH cte(cte_id, new_pos) AS (
           SELECT *
           FROM (VALUES #{values}) as t (id, pos)
          )
          UPDATE #{Issue.table_name}
          SET relative_position = cte.new_pos
          FROM cte
          WHERE cte_id = id
        SQL
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
