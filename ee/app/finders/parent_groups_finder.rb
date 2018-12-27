# frozen_string_literal: true

class ParentGroupsFinder
  attr_accessor :user, :group

  def initialize(user, group)
    @group = group
    @user = user
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def execute
    group.self_and_ancestors.where(id: user&.authorized_groups)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
