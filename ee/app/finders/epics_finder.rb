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
      my_reaction_emoji
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
    items = filter_items(items)
    items = filter_negated_items(items)

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

    epics = Epic.where(group: groups)
    with_confidentiality_access_check(epics, groups)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def filter_items(items)
    items = by_created_at(items)
    items = by_updated_at(items)
    items = by_author(items)
    items = by_timeframe(items)
    items = by_state(items)
    items = by_label(items)
    items = by_parent(items)
    items = by_iids(items)
    items = by_my_reaction_emoji(items)

    starts_with_iid(items)
  end

  def filter_negated_items(items)
    return items unless Feature.enabled?(:not_issuable_queries, group, default_enabled: true)

    # API endpoints send in `nil` values so we test if there are any non-nil
    return items unless not_params&.values&.any?

    items = by_negated_label(items)
    by_negated_author(items)
  end

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

  def with_confidentiality_access_check(epics, groups)
    return epics unless Feature.enabled?(:confidential_epics_query, group)
    return epics if can_read_all_related_groups?(groups)

    epics.not_confidential_or_in_groups(groups_with_confidential_access(groups))
  end

  def groups_with_confidential_access(groups)
    return ::Group.none unless current_user

    # groups is an array, not a relation here so we have to use `map`
    group_ids = groups.map(&:id)
    GroupMember.by_group_ids(group_ids).by_user_id(current_user).non_guests.select(:source_id)
  end

  def can_read_all_related_groups?(groups)
    return false unless current_user

    # If a user is a member of a group, he also inherits access to all subgroups,
    # so here we check if user is member of the top-level group (from the
    # list of groups being requested) - this is checked by
    # `read_confidential_epic` policy. If that's the case we don't need to
    # check membership on subgroups.
    #
    # `groups` is a list of groups in the same group hierarchy, by default
    # these should be ordered by nested level in the group hierarchy in
    # descending order (so top-level first), except if we fetch ancestors
    # - in that case top-level group is group's root parent
    parent = params.fetch(:include_ancestor_groups, false) ? groups.first.root_ancestor : group
    Ability.allowed?(current_user, :read_confidential_epic, parent)
  end
end
