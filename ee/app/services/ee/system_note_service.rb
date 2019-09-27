# frozen_string_literal: true

# SystemNoteService
#
# Used for creating system notes (e.g., when a user references a merge request
# from an issue, an issue's assignee changes, an issue is closed, etc.
module EE
  module SystemNoteService
    extend ActiveSupport::Concern

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

    def design_version_added(version)
      EE::SystemNotes::DesignManagementService.new(version).design_version_added
    end

    def epic_issue(epic, issue, user, type)
      EE::SystemNotes::EpicsService.new(noteable: epic, author: user).epic_issue(issue, type)
    end

    def epic_issue_moved(from_epic, issue, to_epic, user)
      EE::SystemNotes::EpicsService.new(noteable: from_epic, author: user).epic_issue_moved(issue, to_epic)
    end

    def epic_issue_moved_act(subject_epic, issue, object_epic, user, verb:, direction:)
      EE::SystemNotes::EpicsService.new(noteable: subject_epic, author: user).epic_issue_moved_act(issue, object_epic, verb: verb, direction: direction)
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

    def approve_mr(noteable, user)
      ::SystemNotes::MergeRequestsService.new(noteable: noteable, project: noteable.project, author: user).approve_mr
    end

    def unapprove_mr(noteable, user)
      ::SystemNotes::MergeRequestsService.new(noteable: noteable, project: noteable.project, author: user).unapprove_mr
    end

    def change_weight_note(noteable, project, author)
      ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author).change_weight_note
    end

    def change_epic_date_note(noteable, author, date_type, date)
      EE::SystemNotes::EpicsService.new(noteable: noteable, author: author).change_epic_date_note(date_type, date)
    end

    def change_epics_relation(epic, child_epic, user, type)
      EE::SystemNotes::EpicsService.new(noteable: epic, author: user).change_epics_relation(child_epic, type)
    end

    def change_epics_relation_act(subject_epic, user, action, text, text_params)
      EE::SystemNotes::EpicsService.new(noteable: subject_epic, author: user).change_epics_relation_act(action, text, text_params)
    end

    def merge_train(noteable, project, author, merge_train)
      EE::SystemNotes::MergeTrainService.new(noteable: noteable, project: project, author: author).merge_train(merge_train)
    end

    def cancel_merge_train(noteable, project, author)
      EE::SystemNotes::MergeTrainService.new(noteable: noteable, project: project, author: author).cancel_merge_train
    end

    def abort_merge_train(noteable, project, author, reason)
      EE::SystemNotes::MergeTrainService.new(noteable: noteable, project: project, author: author).abort_merge_train(reason)
    end

    def add_to_merge_train_when_pipeline_succeeds(noteable, project, author, sha)
      EE::SystemNotes::MergeTrainService.new(noteable: noteable, project: project, author: author).add_to_merge_train_when_pipeline_succeeds(sha)
    end

    def cancel_add_to_merge_train_when_pipeline_succeeds(noteable, project, author)
      EE::SystemNotes::MergeTrainService.new(noteable: noteable, project: project, author: author).cancel_add_to_merge_train_when_pipeline_succeeds
    end

    def abort_add_to_merge_train_when_pipeline_succeeds(noteable, project, author, reason)
      EE::SystemNotes::MergeTrainService.new(noteable: noteable, project: project, author: author).abort_add_to_merge_train_when_pipeline_succeeds(reason)
    end
  end
end
