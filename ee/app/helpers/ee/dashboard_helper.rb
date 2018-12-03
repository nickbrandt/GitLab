# frozen_string_literal: true

module EE
  module DashboardHelper
    def controller_action_to_child_dashboards(controller = controller_name, action = action_name)
      case "#{controller}##{action}"
      when 'projects#index', 'root#index', 'projects#starred', 'projects#trending'
        %w(projects)
      when 'dashboard#activity'
        %w(starred_project_activity project_activity)
      when 'groups#index'
        %w(groups)
      when 'todos#index'
        %w(todos)
      when 'dashboard#issues'
        %w(issues)
      when 'dashboard#merge_requests'
        %w(merge_requests)
      else
        []
      end
    end

    def user_default_dashboard?(user = current_user)
      controller_action_to_child_dashboards.any? {|dashboard| dashboard == user.dashboard }
    end
  end
end
