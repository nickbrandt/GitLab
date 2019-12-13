# frozen_string_literal: true

class ResourceWeightEvent < ApplicationRecord
  validates :user, presence: true
  validates :issue, presence: true

  belongs_to :user
  belongs_to :issue

  scope :by_issue, ->(issue) { where(issue_id: issue.id) }
end
