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
      return unless validate_epic_issue_action_type(type)

      action = type == :added ? 'epic_issue_added' : 'epic_issue_removed'

      body = "#{type} issue #{issue.to_reference(epic.group)}"

      create_note(NoteSummary.new(epic, nil, user, body, action: action))
    end

    def epic_issue_moved(from_epic, issue, to_epic, user)
      epic_issue_moved_act(from_epic, issue, to_epic, user, verb: 'added', direction: 'from')
      epic_issue_moved_act(to_epic, issue, from_epic, user, verb: 'moved', direction: 'to')
    end

    def epic_issue_moved_act(subject_epic, issue, object_epic, user, verb:, direction:)
      action = 'epic_issue_moved'

      body = "#{verb} issue #{issue.to_reference(subject_epic.group)} #{direction}" \
             " epic #{subject_epic.to_reference(object_epic.group)}"

      create_note(NoteSummary.new(object_epic, nil, user, body, action: action))
    end

    def issue_promoted(noteable, noteable_ref, author, direction:)
      unless [:to, :from].include?(direction)
        raise ArgumentError, "Invalid direction `#{direction}`"
      end

      project = noteable.project

      cross_reference = noteable_ref.to_reference(project || noteable.group)
      body = "promoted #{direction} #{noteable_ref.class.to_s.downcase} #{cross_reference}"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'moved'))
    end

    def issue_on_epic(issue, epic, user, type)
      return unless validate_epic_issue_action_type(type)

      if type == :added
        direction = 'to'
        action = 'issue_added_to_epic'
      else
        direction = 'from'
        action = 'issue_removed_from_epic'
      end

      body = "#{type} #{direction} epic #{epic.to_reference(issue.project)}"

      create_note(NoteSummary.new(issue, issue.project, user, body, action: action))
    end

    def issue_epic_change(issue, epic, user)
      body = "changed epic to #{epic.to_reference(issue.project)}"
      action = 'issue_changed_epic'

      create_note(NoteSummary.new(issue, issue.project, user, body, action: action))
    end

    def validate_epic_issue_action_type(type)
      [:added, :removed].include?(type)
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
      body = if date
               "changed #{date_type} to #{date.strftime('%b %-d, %Y')}"
             else
               "removed the #{date_type}"
             end

      create_note(NoteSummary.new(noteable, nil, author, body, action: 'epic_date_changed'))
    end

    def change_epics_relation(epic, child_epic, user, type)
      note_body = if type == 'relate_epic'
                    "added epic %{target_epic_ref} as %{direction} epic"
                  else
                    "removed %{direction} epic %{target_epic_ref}"
                  end

      change_epics_relation_act(epic, user, type, note_body,
                                { direction: 'child', target_epic_ref: child_epic.to_reference(epic.group) })
      change_epics_relation_act(child_epic, user, type, note_body,
                                { direction: 'parent', target_epic_ref: epic.to_reference(child_epic.group) })
    end

    def change_epics_relation_act(subject_epic, user, action, text, text_params)
      create_note(NoteSummary.new(subject_epic, nil, user, text % text_params, action: action))
    end

    # Called when 'merge train' is executed
    def merge_train(noteable, project, author, merge_train)
      index = merge_train.index

      body = if index == 0
               'started a merge train'
             else
               "added this merge request to the merge train at position #{index + 1}"
             end

      create_note(NoteSummary.new(noteable, project, author, body, action: 'merge'))
    end

    # Called when 'merge train' is canceled
    def cancel_merge_train(noteable, project, author)
      body = 'removed this merge request from the merge train'

      create_note(NoteSummary.new(noteable, project, author, body, action: 'merge'))
    end

    # Called when 'merge train' is aborted
    def abort_merge_train(noteable, project, author, reason)
      body = "removed this merge request from the merge train because #{reason}"

      ##
      # TODO: Abort message should be sent by the system, not a particular user.
      # See https://gitlab.com/gitlab-org/gitlab-foss/issues/63187.
      create_note(NoteSummary.new(noteable, project, author, body, action: 'merge'))
    end

    # Called when 'add to merge train when pipeline succeeds' is executed
    def add_to_merge_train_when_pipeline_succeeds(noteable, project, author, sha)
      body = "enabled automatic add to merge train when the pipeline for #{sha} succeeds"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'merge'))
    end

    # Called when 'add to merge train when pipeline succeeds' is canceled
    def cancel_add_to_merge_train_when_pipeline_succeeds(noteable, project, author)
      body = 'cancelled automatic add to merge train'

      create_note(NoteSummary.new(noteable, project, author, body, action: 'merge'))
    end

    # Called when 'add to merge train when pipeline succeeds' is aborted
    def abort_add_to_merge_train_when_pipeline_succeeds(noteable, project, author, reason)
      body = "aborted automatic add to merge train because #{reason}"

      ##
      # TODO: Abort message should be sent by the system, not a particular user.
      # See https://gitlab.com/gitlab-org/gitlab-foss/issues/63187.
      create_note(NoteSummary.new(noteable, project, author, body, action: 'merge'))
    end

    def auto_resolve_prometheus_alert(noteable, project, author)
      body = 'automatically closed this issue because the alert resolved.'

      create_note(NoteSummary.new(noteable, project, author, body, action: 'closed'))
    end
  end
end
