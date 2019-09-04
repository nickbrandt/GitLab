# frozen_string_literal: true

class ZoomMeeting < ApplicationRecord
  belongs_to :project, required: true
  belongs_to :issue, required: true

  validates :url, presence: true, length: { maximum: 255 }

  validate :check_zoom_url
  validate :check_issue_association

  enum issue_status: {
    added: 1,
    removed: 2
  }

  scope :added_to_issue, -> { where(issue_status: :added) }
  scope :removed_from_issue, -> { where(issue_status: :removed) }

  private

  def check_zoom_url
    return if Gitlab::ZoomLinkExtractor.new(url).links.size == 1

    errors.add(:url, 'must contain one valid Zoom URL')
  end

  def check_issue_association
    return if project == issue&.project

    errors.add(:issue, 'must associate the same project')
  end
end
