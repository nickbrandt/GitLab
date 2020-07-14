# frozen_string_literal: true

# Search for milestones
#
# params - Hash
#   project_ids: Array of project ids or single project id or ActiveRecord relation.
#   group_ids: Array of group ids or single group id or ActiveRecord relation.
#   order - Orders by field default due date asc.
#   title - filter by title.
#   state - filters by state.
#   search - string
#   iids: integer[]

class MilestonesFinder
  include FinderMethods
  include TimeFrameFilter

  attr_reader :params

  def initialize(params = {})
    @params = params
  end

  def execute
    items = Milestone.all
    items = by_groups_and_projects(items)
    items = by_iid(items)
    items = by_title(items)
    items = by_search_title(items)
    items = by_state(items)
    items = by_timeframe(items)
    items = by_search(items)

    order(items)
  end

  private

  def by_groups_and_projects(items)
    items.for_projects_and_groups(params[:project_ids], params[:group_ids])
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_title(items)
    if params[:title]
      items.where(title: params[:title])
    else
      items
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def by_search_title(items)
    if params[:search_title].present?
      items.search_title(params[:search_title])
    else
      items
    end
  end

  def by_search(items)
    if params[:search].present?
      items.search(params[:search])
    else
      items
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_iid(items)
    return items unless params[:iids].present?

    if params[:project_ids].present?
      items.where(iid: params[:iids], project_id: params[:project_ids])
    elsif params[:group_ids].present?
      items.where(iid: params[:iids], group_id: params[:group_ids])
    else
      items
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def by_state(items)
    Milestone.filter_by_state(items, params[:state])
  end

  def order(items)
    sort_by = params[:sort].presence || 'due_date_asc'
    items.sort_by_attribute(sort_by)
  end
end
