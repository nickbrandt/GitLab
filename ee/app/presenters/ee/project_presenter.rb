# frozen_string_literal: true

module EE
  module ProjectPresenter
    extend ::Gitlab::Utils::Override

    override :statistics_buttons
    def statistics_buttons(show_auto_devops_callout:)
      super + extra_statistics_buttons
    end

    def extra_statistics_buttons
      buttons = []

      if can?(current_user, :read_project_security_dashboard, project)
        buttons << security_dashboard_data
      end

      buttons
    end

    def approver_groups
      ::ApproverGroup.filtered_approver_groups(project.approver_groups, current_user)
    end

    private

    def security_dashboard_data
      OpenStruct.new(is_link: false,
                     label: statistic_icon('lock') + _('Security Dashboard'),
                     link: project_security_dashboard_index_path(project),
                     class_modifier: 'default')
    end
  end
end
