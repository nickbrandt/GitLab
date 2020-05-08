# frozen_string_literal: true

# Params:
#   iids: integer[]
#   state: 'open' or 'closed' or 'all'
#   group_id: integer
#   parent_id: integer
#   author_id: integer
#   author_username: string
#   label_name: string
#   search: string
#   sort: string
#   start_date: datetime
#   end_date: datetime
#   created_after: datetime
#   created_before: datetime
#   updated_after: datetime
#   updated_before: datetime
#   include_ancestor_groups: boolean
#   include_descendant_groups: boolean
#   starts_with_iid: string (containing a number)

class EpicsFinder < IssuableFinder
  include TimeFrameFilter

  IID_STARTS_WITH_PATTERN = %r{\A(\d)+\z}.freeze

  def self.scalar_params
    @scalar_params ||= %i[
      parent_id
      author_id
      author_username
      label_name
      start_date
      end_date
      search
    ]
  end

  def self.array_params
    @array_params ||= { label_name: [] }
  end

  def self.valid_iid_query?(query)
    query.match?(IID_STARTS_WITH_PATTERN)
  end

  def klass
    Epic
  end

  def execute
    raise ArgumentError, 'group_id argument is missing' unless params[:group_id]
    return Epic.none unless Ability.allowed?(current_user, :read_epic, group)

    items = init_collection
    items = by_created_at(items)
    items = by_updated_at(items)
    items = by_author(items)
    items = by_timeframe(items)
    items = by_state(items)
    items = by_label(items)
    items = by_parent(items)
    items = by_iids(items)
    items = starts_with_iid(items)

    # This has to be last as we use a CTE as an optimization fence
    # for counts by passing the force_cte param and enabling the
    # attempt_group_search_optimizations feature flag
    # https://www.postgresql.org/docs/current/static/queries-with.html
    items = by_search(items)

    sort(items)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def init_collection
    groups = if params[:iids].present?
               # If we are querying for specific iids, then we should only be looking at
               # those in the group, not any sub-groups (which can have identical iids).
               # The `group` method takes care of checking permissions
               [group]
             else
               # `same_root` should be set only if we are sure that all groups
               # in related_groups have the same ancestor root group
               ::Group.groups_user_can_read_epics(related_groups, current_user, same_root: true)
             end

    Epic.where(group: groups)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def group
    return unless params[:group_id]
    return @group if defined?(@group)

    @group = Group.find(params[:group_id])
  end

  def starts_with_iid(items)
    return items unless params[:iid_starts_with].present?

    query = params[:iid_starts_with]
    raise ArgumentError unless self.class.valid_iid_query?(query)

    items.iid_starts_with(query)
  end

  def related_groups
    include_ancestors = params.fetch(:include_ancestor_groups, false)
    include_descendants = params.fetch(:include_descendant_groups, true)

    if include_ancestors && include_descendants
      group.self_and_hierarchy
    elsif include_ancestors
      group.self_and_ancestors
    elsif include_descendants
      group.self_and_descendants
    else
      Group.id_in(group.id)
    end
  end

  def count_key(value)
    last_value = Array(value).last

    if last_value.is_a?(Integer)
      Epic.states.invert[last_value].to_sym
    else
      last_value.to_sym
    end
  end

  def parent_id?
    params[:parent_id].present?
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_parent(items)
    return items unless parent_id?

    items.where(parent_id: params[:parent_id])
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
