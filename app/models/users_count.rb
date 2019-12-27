class UsersCount < ApplicationRecord
  attribute :total_count, :integer
  attribute :total_only_active, :integer
  attribute :total_not_ghost, :integer
  attribute :active_non_ghost_non_bot, :integer
  attribute :total_member_10_active_and_not_ghost_count, :integer
  attribute :refresh_time, :datetime

  def readonly
    true
  end
end
