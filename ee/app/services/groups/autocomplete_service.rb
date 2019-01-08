# frozen_string_literal: true

module Groups
  class AutocompleteService < Groups::BaseService
    include LabelsAsHash

    # rubocop: disable CodeReuse/ActiveRecord
    def issues
      IssuesFinder.new(current_user, group_id: group.id, include_subgroups: true, state: 'opened')
        .execute
        .preload(project: :namespace)
        .select(:iid, :title, :project_id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def merge_requests
      MergeRequestsFinder.new(current_user, group_id: group.id, include_subgroups: true, state: 'opened')
        .execute
        .preload(target_project: :namespace)
        .select(:iid, :title, :target_project_id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def epics
      # TODO: change to EpicsFinder once frontend supports epics from external groups.
      # See https://gitlab.com/gitlab-org/gitlab-ee/issues/6837
      DeclarativePolicy.user_scope do
        if Ability.allowed?(current_user, :read_epic, group)
          group.epics.select(:iid, :title)
        else
          []
        end
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def milestones
      group_ids = group.self_and_ancestors.public_or_visible_to_user(current_user).pluck(:id)

      MilestonesFinder.new(group_ids: group_ids).execute.select(:iid, :title)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def labels_as_hash(target)
      super(target, group_id: group.id, only_group_labels: true)
    end

    def commands(noteable)
      return [] unless noteable

      QuickActions::InterpretService.new(nil, current_user).available_commands(noteable)
    end
  end
end
