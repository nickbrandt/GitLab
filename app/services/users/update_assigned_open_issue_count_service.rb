# frozen_string_literal: true

module Users
  # Service class for calculating and persisting the number of assigned issues for a user.
  class UpdateAssignedOpenIssueCountService
    attr_accessor :current_user, :target_user, :params

    def initialize(current_user:, target_user:, params: {})
      @target_user, @current_user, @params = target_user, current_user, params.dup
    end

    def execute
      return ServiceResponse.error(message: 'Insufficient permissions') unless current_user

      value = persist_count(params[:count_to_persist] || calculate_count)

      ServiceResponse.success(payload: { count: value })
    end

    private

    def persist_count(count)
      Users::UpdateService.new(current_user, user: target_user, assigned_open_issues_count: count).execute
      count
    end

    def calculate_count
      IssuesFinder.new(target_user, assignee_id: target_user.id, state: 'opened', non_archived: true).execute.count
    end
  end
end
