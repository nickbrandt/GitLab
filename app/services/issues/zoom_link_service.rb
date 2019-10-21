# frozen_string_literal: true

module Issues
  class ZoomLinkService < Issues::BaseService
    def initialize(issue, user)
      super(issue.project, user)

      @issue = issue
      @added_meeting = fetch_added_meeting
    end

    def add_link(link)
      if can_add_link? && (link = parse_link(link))
        success(_('Zoom meeting added'), add_zoom_meeting(link))
      else
        error(_('Failed to add a Zoom meeting'))
      end
    end

    def remove_link
      if can_remove_link?
        success(_('Zoom meeting removed'), remove_zoom_meeting)
      else
        error(_('Failed to remove a Zoom meeting'))
      end
    end

    def can_add_link?
      can? && !@added_meeting
    end

    def can_remove_link?
      can? && !!@added_meeting
    end

    def parse_link(link)
      Gitlab::ZoomLinkExtractor.new(link).links.last
    end

    private

    attr_reader :issue

    def fetch_added_meeting
      ZoomMeeting.canonical_meeting(@issue)
    end

    def track_meeting_added_event
      ::Gitlab::Tracking.event('IncidentManagement::ZoomIntegration', 'add_zoom_meeting', label: 'Issue ID', value: issue.id)
    end

    def track_meeting_removed_event
      ::Gitlab::Tracking.event('IncidentManagement::ZoomIntegration', 'remove_zoom_meeting', label: 'Issue ID', value: issue.id)
    end

    def add_zoom_meeting(link)
      ZoomMeeting.create(
        issue: @issue,
        project: @issue.project,
        issue_status: :added,
        url: link
      )
      issue.zoom_meetings
    end

    def remove_zoom_meeting
      @added_meeting.issue_status = :removed
      @added_meeting.save
      issue.zoom_meetings
    end

    def success(message, zoom_meetings)
      ServiceResponse.success(
        message: message,
        payload: { zoom_meetings: zoom_meetings }
      )
    end

    def error(message)
      ServiceResponse.error(message: message)
    end

    def can?
      current_user.can?(:update_issue, project)
    end
  end
end
