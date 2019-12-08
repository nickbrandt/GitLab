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

class EpicsFinder < IssuableFinder
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

  def klass
    Epic
  end

  def execute
    raise ArgumentError, 'group_id argument is missing' unless group

    items = init_collection
    items = by_created_at(items)
    items = by_updated_at(items)
    items = by_search(items)
    items = by_author(items)
    items = by_timeframe(items)
    items = by_state(items)
    items = by_label(items)
    items = by_parent(items)
    items = by_iids(items)

    sort(items)
  end

  def group
    return unless params[:group_id]
    return @group if defined?(@group)

    group = Group.find(params[:group_id])

    unless Ability.allowed?(current_user, :read_epic, group)
      raise ActiveRecord::RecordNotFound.new("Could not find a Group with ID #{params[:group_id]}")
    end

    @group = group
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

  # rubocop: disable CodeReuse/ActiveRecord
  def by_timeframe(items)
    return items unless params[:start_date] && params[:end_date]

    end_date = params[:end_date].to_date
    start_date = params[:start_date].to_date

    items
      .where('epics.start_date is not NULL or epics.end_date is not NULL')
      .where('epics.start_date is NULL or epics.start_date <= ?', end_date)
      .where('epics.end_date is NULL or epics.end_date >= ?', start_date)
  rescue ArgumentError
    items
  end
  # rubocop: enable CodeReuse/ActiveRecord

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
