# frozen_string_literal: true

module EE::GroupMembersFinder
  extend ActiveSupport::Concern

  prepended do
    attr_reader :group
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def not_managed
    group.group_members.non_owners.joins(:user)
      .where("users.managing_group_id IS NULL OR users.managing_group_id != ?", group.id)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
