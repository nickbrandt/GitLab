# frozen_string_literal: true

module Issues
  class ReorderService < Issues::BaseService
    def execute(issue)
      return false unless can?(current_user, :update_issue, issue)
      return false if group && !can?(current_user, :read_group, group)

      attrs = issue_params(group)
      return move_to_end(issue) if params[:placement] == :end
      return false if attrs.empty?

      update(issue, attrs)
    end

    private

    def move_to_end(issue)
      issue.move_to_end
      return false unless issue.save

      rebalance_if_needed(issue)
      true
    rescue RelativePositioning::NoSpaceLeft
      gates = [issue.project, issue.project.group].compact

      if gates.any? { |gate| Feature.enabled?(:rebalance_issues, gate) }
        IssueRebalancingWorker.perform_async(nil, issue.project_id)
      end

      issue.update(relative_position: RelativePositioning::MAX_POSITION)
    end

    def group
      return unless params[:group_full_path]

      @group ||= Group.find_by_full_path(params[:group_full_path])
    end

    def update(issue, attrs)
      ::Issues::UpdateService.new(project, current_user, attrs).execute(issue)
    rescue ActiveRecord::RecordNotFound
      false
    end

    def issue_params(group)
      attrs = {}

      if move_between_ids
        attrs[:move_between_ids] = move_between_ids
        attrs[:board_group_id]   = group&.id
      end

      attrs
    end

    def move_between_ids
      ids = [params[:move_after_id], params[:move_before_id]]
              .map(&:to_i)
              .map { |m| m > 0 ? m : nil }

      ids.any? ? ids : nil
    end
  end
end
