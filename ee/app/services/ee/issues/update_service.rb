# frozen_string_literal: true

module EE
  module Issues
    module UpdateService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(issue)
        handle_epic(issue)
        handle_relate(issue)
        result = super

        if issue.previous_changes.include?(:milestone_id) && issue.epic
          issue.epic.update_start_and_due_dates
        end

        result
      end

      private

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

      def handle_relate(issue)
        return unless params.key?(:related_issues)

        relate_param = params.delete(:related_issues)

        if relate_param
          relate_param.each do |issuable|
            IssueLinks::CreateService.new(issuable, current_user, { target_issue: issue }).execute
          end
        end
      end
    end
  end
end
