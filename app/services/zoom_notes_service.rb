# frozen_string_literal: true

class ZoomNotesService
  def initialize(issue, project, current_user, old_associations)
    @issue = issue
    @project = project
    @current_user = current_user
    @old_zoom_meetings = old_associations ? old_associations.fetch(:zoom_meetings, []) : []
  end

  def execute
    return if @issue.zoom_meetings == @old_zoom_meetings

    if zoom_link_added?
      zoom_link_added_notification
    else
      zoom_link_removed_notification
    end
  end

  private

  def zoom_link_added?
    meetings = @issue.zoom_meetings.select { |z| z.issue_status == "added" }
    !meetings.empty?
  end

  def zoom_link_added_notification
    SystemNoteService.zoom_link_added(@issue, @project, @current_user)
  end

  def zoom_link_removed_notification
    SystemNoteService.zoom_link_removed(@issue, @project, @current_user)
  end
end
