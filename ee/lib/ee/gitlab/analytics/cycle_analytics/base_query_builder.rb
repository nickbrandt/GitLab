# frozen_string_literal: true

module EE::Gitlab::Analytics::CycleAnalytics::BaseQueryBuilder
  extend ::Gitlab::Utils::Override

  override :build
  def build
    filter_by_project_ids(super)
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def filter_by_project_ids(query)
    project_ids = Array(params[:project_ids])

    query = query.where(project_id: project_ids) if project_ids.any?
    query
  end
  # rubocop: enable CodeReuse/ActiveRecord

  override :filter_by_parent_model
  # rubocop: disable CodeReuse/ActiveRecord
  def filter_by_parent_model(query)
    return super unless parent_class.eql?(Group)

    if subject_class.eql?(Issue)
      join_groups(query.joins(:project))
    elsif subject_class.eql?(MergeRequest)
      join_groups(query.joins(:target_project))
    else
      raise ArgumentError, "unknown subject_class: #{subject_class}"
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def join_groups(query)
    query.joins(Arel.sql("INNER JOIN (#{stage.parent.self_and_descendants.to_sql}) namespaces ON namespaces.id=projects.namespace_id"))
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
