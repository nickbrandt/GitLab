# frozen_string_literal: true

module EpicLinks
  class CreateService < IssuableLinks::CreateService
    def execute
      return error('Epic hierarchy level too deep', 409) if parent_ancestors_count >= 4

      super
    end

    private

    def relate_issuables(referenced_epic)
      affected_epics = [issuable]
      affected_epics << referenced_epic if referenced_epic.parent

      referenced_epic.update(parent: issuable)
      affected_epics.each(&:update_start_and_due_dates)
    end

    def linkable_issuables(epics)
      @linkable_issuables ||= begin
        return [] unless can?(current_user, :admin_epic, issuable.group)

        epics.select do |epic|
          linkable_epic?(epic)
        end
      end
    end

    def linkable_epic?(epic)
      return false if epic == issuable
      return false if previous_related_issuables.include?(epic)
      return false if level_depth_exceeded?(epic)
      return false if issuable.has_ancestor?(epic)

      issuable_group_descendants.include?(epic.group)
    end

    def references(extractor)
      extractor.epics
    end

    def extractor_context
      { group: issuable.group }
    end

    def previous_related_issuables
      issuable.children.to_a
    end

    def issuable_group_descendants
      @descendants ||= issuable.group.self_and_descendants
    end

    def level_depth_exceeded?(epic)
      depth_level(epic) + parent_ancestors_count >= 5
    end

    def depth_level(epic)
      epic.descendants.count + 1 # level including epic -> therefore +1
    end

    def parent_ancestors_count
      @parent_ancestors_count ||= issuable.ancestors.count
    end

    def issuables_assigned_message
      'Epic(s) already assigned'
    end

    def issuables_not_found_message
      'No Epic found for given params'
    end
  end
end
