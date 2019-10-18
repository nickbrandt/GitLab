# frozen_string_literal: true

module EE
  module Issues
    module CreateService
      extend ::Gitlab::Utils::Override

      override :filter_params
      def filter_params(issue)
        epic_iid = params.delete(:epic_iid)
        group = issue.project.group
        if epic_iid.present? && group && can?(current_user, :admin_epic, group)
          finder = EpicsFinder.new(current_user, group_id: group.id)
          params[:epic] = finder.find_by!(iid: epic_iid) # rubocop: disable CodeReuse/ActiveRecord
        end

        super
      end

      override :before_create
      def before_create(issue)
        handle_issue_epic_link(issue)

        super
      end

      def handle_issue_epic_link(issue)
        return unless params.key?(:epic)

        epic_param = params.delete(:epic)

        if epic_param
          EpicIssues::CreateService.new(epic_param, current_user, { target_issuable: issue }).execute
        else
          link = EpicIssue.find_by_issue_id(issue.id)

          return unless link

          EpicIssues::DestroyService.new(link, current_user).execute
        end
      end
    end
  end
end
