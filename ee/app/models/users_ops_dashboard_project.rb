# frozen_string_literal: true

class UsersOpsDashboardProject < ApplicationRecord
  belongs_to :project
  belongs_to :user

  validates :user, presence: true
  validates :user_id, uniqueness: { scope: [:project_id] }
  validates :project, presence: true

  def self.distinct_users(users)
    select('distinct user_id').joins(:user).merge(users)
  end
end
