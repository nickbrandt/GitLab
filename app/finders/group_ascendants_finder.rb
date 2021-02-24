# frozen_string_literal: true

class GroupAscendantsFinder < UnionFinder
  def initialize(current_user: nil, group:, params: {})
    @current_user = current_user
    @group = group
    @params = params
  end

  def execute
    return Group.none unless authorized? || has_ancestors?

    items = ascendants_for_groups.map do |item|
      item = visible_to_user(item)
      item = exclude_group_ids(item)
      item = with_shared_groups(item)
      item
    end

    find_union(items, Group).with_route.order_id_asc
  end

  private

  attr_reader :current_user, :group, :params

  def has_ancestors?
    group.parent_id.present?
  end

  def authorized?
    Ability.allowed?(current_user, :read_group, group)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def ascendants_for_group
    @ascendants_for_group ||= Gitlab::ObjectHierarchy.new(Group.where(id: group.id))
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def visible_to_user(item)
    # Something similar to GroupDescendatsFinder#all_visibile_descendat_group
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def with_shared_groups(groups)
    return groups unless params[:project_id].present? && params[:with_shared].present?

    shared_groups = Project.find(params[:project_id]).invited_groups

    if params[:shared_min_access_level]
      shared_groups = shared_groups.where(
        'project_group_links.group_access >= ?', params[:shared_min_access_level]
      )
    end

    shared_groups
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
