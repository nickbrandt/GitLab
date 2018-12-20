# frozen_string_literal: true

module EpicLinks
  class ListService < IssuableLinks::ListService
    private

    def child_issuables
      return [] unless issuable&.group&.feature_available?(:epics)

      EpicsFinder.new(current_user, parent_id: issuable.id, group_id: issuable.group.id).execute
    end

    def reference(epic)
      epic.to_reference(issuable.group)
    end

    def issuable_path(epic)
      group_epic_path(epic.group, epic)
    end

    def relation_path(epic)
      group_epic_link_path(epic.group, issuable.iid, epic.id)
    end

    def to_hash(object)
      {
        id: object.id,
        title: object.title,
        state: object.state,
        reference: reference(object),
        path: issuable_path(object),
        relation_path: relation_path(object)
      }
    end
  end
end
