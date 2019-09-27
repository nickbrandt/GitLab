# frozen_string_literal: true

# SystemNoteService
#
# Used for creating system notes (e.g., when a user references a merge request
# from an issue, an issue's assignee changes, an issue is closed, etc.)
module SystemNoteService
  extend self

  # Called when commits are added to a Merge Request
  #
  # noteable         - Noteable object
  # project          - Project owning noteable
  # author           - User performing the change
  # new_commits      - Array of Commits added since last push
  # existing_commits - Array of Commits added in a previous push
  # oldrev           - Optional String SHA of a previous Commit
  #
  # Returns the created Note object
  def add_commits(noteable, project, author, new_commits, existing_commits = [], oldrev = nil)
    ::SystemNotes::CommitService.new(noteable: noteable, project: project, author: author).add_commits(new_commits, existing_commits, oldrev)
  end

  def tag_commit(noteable, project, author, tag_name)
    ::SystemNotes::CommitService.new(noteable: noteable, project: project, author: author).tag_commit(tag_name)
  end

  def change_assignee(noteable, project, author, assignee)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).change_assignee(assignee)
  end

  def change_issuable_assignees(issuable, project, author, old_assignees)
    ::SystemNotes::IssuablesService.new(noteable: issuable, project: project, author: author).change_issuable_assignees(old_assignees)
  end

  def change_milestone(noteable, project, author, milestone)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).change_milestone(milestone)
  end

  def change_due_date(noteable, project, author, due_date)
    ::SystemNotes::TimeTrackingService.new(noteable: noteable, noteable: project, noteable: author).change_due_date(due_date)
  end

  def change_time_estimate(noteable, project, author)
    ::SystemNotes::TimeTrackingService.new(noteable: noteable, project: project, author: author).change_time_estimate
  end

  def change_time_spent(noteable, project, author)
    ::SystemNotes::TimeTrackingService.new(noteable: noteable, project: project, author: author).change_time_spent
  end

  def change_status(noteable, project, author, status, source = nil)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).change_status(status, source)
  end

  def merge_when_pipeline_succeeds(noteable, project, author, sha)
    ::SystemNotes::MergeRequestsService.new(noteable: noteable, project: project, author: author).merge_when_pipeline_succeeds(sha)
  end

  def cancel_merge_when_pipeline_succeeds(noteable, project, author)
    ::SystemNotes::MergeRequestsService.new(noteable: noteable, project: project, author: author).cancel_merge_when_pipeline_succeeds
  end

  def abort_merge_when_pipeline_succeeds(noteable, project, author, reason)
    ::SystemNotes::MergeRequestsService.new(noteable: noteable, project: project, author: author).abort_merge_when_pipeline_succeeds(reason)
  end

  def handle_merge_request_wip(noteable, project, author)
    ::SystemNotes::MergeRequestsService.new(noteable: noteable, project: project, author: author).handle_merge_request_wip
  end

  def add_merge_request_wip_from_commit(noteable, project, author, commit)
    ::SystemNotes::MergeRequestsService.new(noteable: noteable, project: project, author: author).add_merge_request_wip_from_commit(commit)
  end

  def resolve_all_discussions(merge_request, project, author)
    ::SystemNotes::MergeRequestsService.new(noteable: merge_request, project: project, author: author).resolve_all_discussions
  end

  def discussion_continued_in_issue(discussion, project, author, issue)
    ::SystemNotes::MergeRequestsService.new(project: project, author: author).discussion_continued_in_issue(discussion, issue)
  end

  def diff_discussion_outdated(discussion, project, author, change_position)
    ::SystemNotes::MergeRequestsService.new(project: project, author: author).diff_discussion_outdated(discussion, change_position)
  end

  def change_title(noteable, project, author, old_title)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).change_title(old_title)
  end

  def change_description(noteable, project, author)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).change_description
  end

  def change_issue_confidentiality(issue, project, author)
    ::SystemNotes::IssuablesService.new(noteable: issue, project: project, author: author).change_issue_confidentiality
  end

  def change_branch(noteable, project, author, branch_type, old_branch, new_branch)
    ::SystemNotes::MergeRequestsService.new(noteable: noteable, project: project, author: author).change_branch(branch_type, old_branch, new_branch)
  end

  def change_branch_presence(noteable, project, author, branch_type, branch, presence)
    ::SystemNotes::MergeRequestsService.new(noteable: noteable, project: project, author: author).change_branch_presence(branch_type, branch, presence)
  end

  def new_issue_branch(issue, project, author, branch, branch_project: nil)
    ::SystemNotes::MergeRequestsService.new(noteable: issue, project: project, author: author).new_issue_branch(branch, branch_project: branch_project)
  end

  def new_merge_request(issue, project, author, merge_request)
    ::SystemNotes::MergeRequestsService.new(noteable: issue, project: project, author: author).new_merge_request(merge_request)
  end

  def cross_reference(noteable, mentioner, author)
    ::SystemNotes::IssuablesService.new(noteable: noteable, author: author).cross_reference(mentioner)
  end

  def cross_reference_exists?(noteable, mentioner)
    ::SystemNotes::IssuablesService.new(noteable: noteable).cross_reference_exists?(mentioner)
  end

  def change_task_status(noteable, project, author, new_task)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).change_task_status(new_task)
  end

  def noteable_moved(noteable, project, noteable_ref, author, direction:)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).noteable_moved(noteable_ref, direction)
  end

  def mark_duplicate_issue(noteable, project, author, canonical_issue)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).mark_duplicate_issue(canonical_issue)
  end

  def mark_canonical_issue_of_duplicate(noteable, project, author, duplicate_issue)
    ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).mark_canonical_issue_of_duplicate(duplicate_issue)
  end

  def discussion_lock(issuable, author)
    ::SystemNotes::IssuablesService.new(noteable: issuable, project: issuable.project, author: author).discussion_lock
  end

  def cross_reference_disallowed?(noteable, mentioner)
    ::SystemNotes::IssuablesService.new(noteable: noteable).cross_reference_disallowed?(mentioner)
  end

  def zoom_link_added(issue, project, author)
    ::SystemNotes::ZoomService.new(noteable: issue, project: project, author: author).zoom_link_added
  end

  def zoom_link_removed(issue, project, author)
    ::SystemNotes::ZoomService.new(noteable: issue, project: project, author: author).zoom_link_removed
  end

  # TODO: Just added for testing
  def new_commit_summary(new_commits)
    ::SystemNotes::CommitService.new.new_commit_summary(new_commits)
  end
end

SystemNoteService.prepend_if_ee('EE::SystemNoteService')
