# frozen_string_literal: true

# ZoomMeetingValidator
#
# Custom validator to TODO
#
class ZoomMeetingValidator < ActiveModel::Validator
  def validate(zoom_meeting)
    unless Gitlab::ZoomLinkExtractor.new(zoom_meeting.url).links.size == 1
      zoom_meeting.errors.add(:url, 'must contain one valid Zoom URL')
    end
    unless zoom_meeting.project == zoom_meeting.issue&.project
      zoom_meeting.errors.add(:issue, 'must associate the same project')
    end
    true
  end
end
