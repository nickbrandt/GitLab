# frozen_string_literal: true

module Epics
  class IssuePromoteService < ::Issuable::Clone::BaseService
    PromoteError = Class.new(StandardError)

    def execute(issue)
      @group = issue.project.group

      unless @group
        raise PromoteError, 'Cannot promote issue because it does not belong to a group!'
      end

      unless current_user.can?(:admin_issue, issue) && current_user.can?(:create_epic, @group)
        raise PromoteError, 'Cannot promote issue due to insufficient permissions!'
      end

      super

      track_event
      new_entity
    end

    private

    def track_event
      ::Gitlab::Tracking.event(
        'epics', 'promote', property: 'issue_id', value: original_entity.id
      )
    end

    def create_new_entity
      @new_entity = Epics::CreateService.new(@group, current_user, params).execute
    end

    def update_old_entity
      super

      mark_as_promoted
    end

    def mark_as_promoted
      original_entity.update(promoted_to_epic: new_entity)
    end

    def params
      {
        title: original_entity.title
      }
    end

    def add_note_from
      SystemNoteService.issue_promoted(new_entity, original_entity, current_user, direction: :from)
    end

    def add_note_to
      SystemNoteService.issue_promoted(original_entity, new_entity, current_user, direction: :to)
    end
  end
end
