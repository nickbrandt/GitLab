# frozen_string_literal: true

module EE
  module Issues
    module BaseService
      extend ::Gitlab::Utils::Override

      def filter_params(issue)
        set_epic_param(issue)
        super
      end

      def handle_epic(issue)
        set_epic_param(issue)

        return unless params.key?(:epic)

        if epic_param
          EpicIssues::CreateService.new(epic_param, current_user, { target_issuable: issue }).execute
        else
          link = EpicIssue.find_by_issue_id(issue.id)

          return unless link

          EpicIssues::DestroyService.new(link, current_user).execute
        end

        params.delete(:epic)
      end

      def set_epic_param(issue)
        return unless epic_param_present?

        epic = epic_param || find_epic(issue)

        unless epic
          params[:epic] = nil
          return
        end

        unless can?(current_user, :admin_epic, epic)
          raise ::Gitlab::Access::AccessDeniedError
        end

        params[:epic] = epic
      end

      def find_epic(issue)
        epic_id = params.delete(:epic_id)
        return if epic_id.to_i == 0

        group = issue.project.group
        return unless group.present?

        EpicsFinder.new(current_user, group_id: group.id,
                        include_ancestor_groups: true).find(epic_id)
      end

      def epic_param
        params[:epic]
      end

      def epic_param_present?
        params.key?(:epic) || params.key?(:epic_id)
      end
    end
  end
end
