# frozen_string_literal: true

class EpicDescendantsFinder
  attr_reader :epic, :current_user

  def initialize(epic:, current_user:)
    @epic = epic
    @current_user = current_user
  end

  def execute
    descendants = epic.descendants
    # TODO: another option is to use CTE subquery
    # Group.where(id: descendants.select(:group_id)
    groups = Group.where(id: descendants.select(:group_id))
    groups = groups_user_can_read_epics(groups)
    descendants.where(group_id: groups)
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def groups_user_can_read_epics(groups)
    groups = Gitlab::GroupPlansPreloader.new.preload(groups)

    DeclarativePolicy.user_scope do
      groups.select { |g| Ability.allowed?(current_user, :read_epic, g) }
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

