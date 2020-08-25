# frozen_string_literal: true

class IssueRebalancingService
  MAX_ISSUE_COUNT = 10_000
  TooManyIssues = Class.new(StandardError)

  attr_reader :issue

  def initialize(issue)
    @issue = issue
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def execute
    gates = [issue.project, issue.project.group].compact
    return unless gates.any? { |gate| Feature.enabled?(:rebalance_issues, gate) }

    base = Issue.relative_positioning_query_base(issue)

    n = base.count

    if n > MAX_ISSUE_COUNT
      raise TooManyIssues, "#{n} issues"
    end

    range = RelativePositioning::MAX_POSITION - RelativePositioning::MIN_POSITION
    gaps = n - 1
    gap_size = 0
    ratio = 0.5

    while gap_size < RelativePositioning::MIN_GAP && ratio < 1
      gap_size = [RelativePositioning::IDEAL_DISTANCE, (ratio * range) / gaps].min.floor
      ratio += 0.1
    end

    # If there are 4 billion issues, then we cannot rebalance them
    raise TooManyIssues if gap_size < RelativePositioning::MIN_GAP

    start = RelativePositioning::START_POSITION - (gaps / 2) * gap_size

    Issue.transaction do
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
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
