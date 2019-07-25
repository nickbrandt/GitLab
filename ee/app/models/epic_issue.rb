# frozen_string_literal: true

class EpicIssue < ApplicationRecord
  include RelativePositioning

  validates :epic, :issue, presence: true
  validates :issue, uniqueness: true

  belongs_to :epic
  belongs_to :issue

  alias_attribute :parent_ids, :epic_id

  scope :in_epic, ->(epic_id) { where(epic_id: epic_id) }

  def self.relative_positioning_query_base(epic_issue)
    in_epic(epic_issue.parent_ids)
  end

  def self.relative_positioning_parent_column
    :epic_id
  end
end
