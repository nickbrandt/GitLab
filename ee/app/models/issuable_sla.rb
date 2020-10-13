# frozen_string_literal: true

class IssuableSla < ApplicationRecord
  belongs_to :issue, optional: false
  validates :due_at, presence: true

  scope :exceeded_for_issues, -> { includes(:issue).merge(Issue.opened).where('due_at < ?', Time.current) }
end
