# frozen_string_literal: true

module EE
  module Issues
    module CreateService
      extend ::Gitlab::Utils::Override

      override :before_create
      def before_create(issue)
        handle_issue_epic_link(issue)

        super
      end

      def handle_issue_epic_link(issue)
        return unless params.key?(:epic)

        epic = params.delete(:epic)

        if epic
          issue.confidential = true if epic.confidential?

          EpicIssues::CreateService.new(epic, current_user, { target_issuable: issue }).execute
        else
          destroy_epic_link(issue)
        end
      end

      def destroy_epic_link(issue)
        link = EpicIssue.find_by_issue_id(issue.id)

        return unless link

        EpicIssues::DestroyService.new(link, current_user).execute
      end
    end
  end
end
