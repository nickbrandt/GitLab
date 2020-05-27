# frozen_string_literal: true

module EE
  module Issues
    module UpdateService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(issue)
        handle_epic(issue)
        handle_promotion(issue)

        result = super

        if issue.previous_changes.include?(:milestone_id) && issue.epic
          Epics::UpdateDatesService.new([issue.epic]).execute
        end

        StatusPage.trigger_publish(project, current_user, issue) if issue.valid?

        result
      end

      override :handle_changes
      def handle_changes(issue, _options)
        super

        handle_iteration_change(issue)
      end

      private

      def handle_iteration_change(issue)
        return unless issue.previous_changes.include?('sprint_id')

        send_iteration_change_notification(issue)
      end

      def send_iteration_change_notification(issue)
        if issue.iteration.nil?
          notification_service.async.removed_iteration_issue(issue, current_user)
        else
          notification_service.async.changed_iteration_issue(issue, issue.iteration, current_user)
        end
      end

      def handle_promotion(issue)
        return unless params.delete(:promote_to_epic)

        Epics::IssuePromoteService.new(issue.project, current_user).execute(issue)
      end

      def handle_epic(issue)
        return unless params.key?(:epic)

        epic_param = params.delete(:epic)

        if epic_param
          EpicIssues::CreateService.new(epic_param, current_user, { target_issuable: issue }).execute
        else
          link = EpicIssue.find_by(issue_id: issue.id) # rubocop: disable CodeReuse/ActiveRecord

          return unless link

          EpicIssues::DestroyService.new(link, current_user).execute
        end
      end
    end
  end
end
