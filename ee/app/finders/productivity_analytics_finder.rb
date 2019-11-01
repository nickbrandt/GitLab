# frozen_string_literal: true

class ProductivityAnalyticsFinder < MergeRequestsFinder
  def self.array_params
    super.merge(days_to_merge: [])
  end

  def self.scalar_params
    @scalar_params ||= super + [:merged_at_before, :merged_at_after]
  end

  def filter_items(_items)
    items = by_days_to_merge(super)
    by_merged_at(items)
  end

  private

  def metrics_table
    MergeRequest::Metrics.arel_table.alias(MergeRequest::Metrics.table_name)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_days_to_merge(items)
    return items unless params[:days_to_merge].present?

    items.joins(:metrics).where("#{days_to_merge_column} IN (?)", params[:days_to_merge].flatten.map(&:to_i))
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def days_to_merge_column
    "date_part('day',merge_request_metrics.merged_at - merge_requests.created_at)"
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_merged_at(items)
    return items unless params[:merged_at_after] || params[:merged_at_before]

    items = items.joins(:metrics)
    items = items.where(metrics_table[:merged_at].gteq(params[:merged_at_after])) if params[:merged_at_after]
    items = items.where(metrics_table[:merged_at].lteq(params[:merged_at_before])) if params[:merged_at_before]

    items
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
