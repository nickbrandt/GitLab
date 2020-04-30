# frozen_string_literal: true

# SystemNoteService
#
# Used for creating system notes (e.g., when a user references a merge request
# from an issue, an issue's assignee changes, an issue is closed, etc.
module EE
  module SystemNoteService
    extend ActiveSupport::Concern
    include ActionView::RecordIdentifier

    prepended do
      # ::SystemNoteService wants the methods to be available as both class and
      # instance methods. This removes the need for having to both `include` and
      # `extend` this module everywhere it is used.
      extend_if_ee('EE::SystemNoteService') # rubocop: disable Cop/InjectEnterpriseEditionModule
    end

    def relate_issue(noteable, noteable_ref, user)
      ::SystemNotes::IssuablesService.new(noteable: noteable, project: noteable.project, author: user).relate_issue(noteable_ref)
    end

    def unrelate_issue(noteable, noteable_ref, user)
      ::SystemNotes::IssuablesService.new(noteable: noteable, project: noteable.project, author: user).unrelate_issue(noteable_ref)
    end

    # Parameters:
    #   - version [DesignManagement::Version]
    #
    # Example Note text:
    #
    #   "added [1 designs](link-to-version)"
    #   "changed [2 designs](link-to-version)"
    #
    # Returns [Array<Note>]: the created Note objects
    def design_version_added(version)
      EE::SystemNotes::DesignManagementService.new(noteable: version.issue,
                                                   project: version.issue.project,
                                                   author: version.author).design_version_added(version)
    end

    # Called when a new discussion is created on a design
    #
    # discussion_note - DiscussionNote
    #
    # Example Note text:
    #
    #   "started a discussion on screen.png"
    #
    # Returns the created Note object
    def design_discussion_added(discussion_note)
      design = discussion_note.noteable
      EE::SystemNotes::DesignManagementService.new(noteable: design.issue,
                                                   project: design.project,
                                                   author: discussion_note.author).design_discussion_added(discussion_note)
    end

    def epic_issue(epic, issue, user, type)
      EE::SystemNotes::EpicsService.new(noteable: epic, author: user).epic_issue(issue, type)
    end

    def epic_issue_moved(from_epic, issue, to_epic, user)
      EE::SystemNotes::EpicsService.new(noteable: from_epic, author: user).epic_issue_moved(issue, to_epic)
    end

    def issue_promoted(noteable, noteable_ref, author, direction:)
      EE::SystemNotes::EpicsService.new(noteable: noteable, author: author).issue_promoted(noteable_ref, direction: direction)
    end

    def issue_on_epic(issue, epic, user, type)
      EE::SystemNotes::EpicsService.new(noteable: epic, author: user).issue_on_epic(issue, type)
    end

    def issue_epic_change(issue, epic, user)
      EE::SystemNotes::EpicsService.new(noteable: epic, author: user).issue_epic_change(issue)
    end

    # Called when the merge request is approved by user
    #
    # noteable - Noteable object
    # user     - User performing approve
    #
    # Example Note text:
    #
    #   "approved this merge request"
    #
    # Returns the created Note object
    def approve_mr(noteable, user)
      ::SystemNotes::MergeRequestsService.new(noteable: noteable, project: noteable.project, author: user).approve_mr
    end

    def unapprove_mr(noteable, user)
      ::SystemNotes::MergeRequestsService.new(noteable: noteable, project: noteable.project, author: user).unapprove_mr
    end

    # Called when the weight of a Noteable is changed
    #
    # noteable   - Noteable object
    # project    - Project owning noteable
    # author     - User performing the change
    #
    # Example Note text:
    #
    #   "removed the weight"
    #
    #   "changed weight to 4"
    #
    # Returns the created Note object
    def change_weight_note(noteable, project, author)
      ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).change_weight_note
    end

    # Called when the health_stauts of an Issue is changed
    #
    # noteable   - Noteable object
    # project    - Project owning noteable
    # author     - User performing the change
    #
    # Example Note text:
    #
    #   "removed the health status"
    #   "changed health status to 'at risk'"
    #
    # Returns the created Note object
    def change_health_status_note(noteable, project, author)
      ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).change_health_status_note
    end

    # Called when the start or end date of an Issuable is changed
    #
    # noteable   - Noteable object
    # author     - User performing the change
    # date_type  - 'start date' or 'finish date'
    # date       - New date
    #
    # Example Note text:
    #
    #   "changed start date to FIXME"
    #
    # Returns the created Note object
    def change_epic_date_note(noteable, author, date_type, date)
      EE::SystemNotes::EpicsService.new(noteable: noteable, author: author).change_epic_date_note(date_type, date)
    end

    def change_epics_relation(epic, child_epic, user, type)
      EE::SystemNotes::EpicsService.new(noteable: epic, author: user).change_epics_relation(child_epic, type)
    end

    # Called when 'merge train' is executed
    def merge_train(noteable, project, author, merge_train)
      EE::SystemNotes::MergeTrainService.new(noteable: noteable, project: project, author: author).enqueue(merge_train)
    end

    # Called when 'merge train' is canceled
    def cancel_merge_train(noteable, project, author)
      EE::SystemNotes::MergeTrainService.new(noteable: noteable, project: project, author: author).cancel
    end

    # Called when 'merge train' is aborted
    def abort_merge_train(noteable, project, author, reason)
      EE::SystemNotes::MergeTrainService.new(noteable: noteable, project: project, author: author).abort(reason)
    end

    # Called when 'add to merge train when pipeline succeeds' is executed
    def add_to_merge_train_when_pipeline_succeeds(noteable, project, author, sha)
      EE::SystemNotes::MergeTrainService.new(noteable: noteable, project: project, author: author).add_when_pipeline_succeeds(sha)
    end

    # Called when 'add to merge train when pipeline succeeds' is canceled
    def cancel_add_to_merge_train_when_pipeline_succeeds(noteable, project, author)
      EE::SystemNotes::MergeTrainService.new(noteable: noteable, project: project, author: author).cancel_add_when_pipeline_succeeds
    end

    # Called when 'add to merge train when pipeline succeeds' is aborted
    def abort_add_to_merge_train_when_pipeline_succeeds(noteable, project, author, reason)
      EE::SystemNotes::MergeTrainService.new(noteable: noteable, project: project, author: author).abort_add_when_pipeline_succeeds(reason)
    end

    # Called when state is changed for 'vulnerability'
    def change_vulnerability_state(noteable, author)
      EE::SystemNotes::VulnerabilitiesService.new(noteable: noteable, project: noteable.project, author: author).change_vulnerability_state
    end

    def publish_issue_to_status_page(noteable, project, author)
      ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).publish_issue_to_status_page
    end
  end
end
