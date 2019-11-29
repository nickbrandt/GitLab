# frozen_string_literal: true

module EE
  module Issues
    module BaseService
      extend ::Gitlab::Utils::Override

      override :filter_params
      def filter_params(issue)
        set_epic_param(issue)
        super
      end

      private

      def set_epic_param(issue)
        epic = find_epic(issue)
        return unless epic

        unless can?(current_user, :admin_epic, epic)
          raise ::Gitlab::Access::AccessDeniedError
        end

        params[:epic] = epic
      end

      def find_epic(issue)
        id = params.delete(:epic_id)
        return unless id.present?

        group = issue.project.group
        return unless group.present?

        EpicsFinder.new(current_user, group_id: group.id,
                        include_ancestor_groups: true).find(id)
      end
    end
  end
end
