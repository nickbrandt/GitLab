# frozen_string_literal: true

module EE
  module EnvironmentsHelper
    def environments_list_data
      ee_environments_list_data = {
        "canary_deployment_feature_id" => UserCalloutsHelper::CANARY_DEPLOYMENT,
        "show-canary-deployment-callout" => show_canary_deployment_callout?(@project).to_s,
        "user-callouts-path" => user_callouts_path,
        "lock-promotion-svg-path" => image_path('illustrations/lock_promotion.svg'),
        "help-canary-deployments-path" => help_page_path('user/project/canary_deployments')
      }

      super.merge(ee_environments_list_data)
    end

    def environments_folder_list_view_data
      ee_environments_folder_list_view_data = {
        "canary_deployment_feature_id" => UserCalloutsHelper::CANARY_DEPLOYMENT,
        "show-canary-deployment-callout" => show_canary_deployment_callout?(@project).to_s,
        "user-callouts-path" => user_callouts_path,
        "lock-promotion-svg-path" => image_path('illustrations/lock_promotion.svg'),
        "help-canary-deployments-path" => help_page_path('user/project/canary_deployments')
      }

      super.merge(ee_environments_folder_list_view_data)
    end

    def metrics_data(project, environment)
      ee_metrics_data = {}
      ee_metrics_data["logs_path"] = project_logs_path(project, environment_name: environment.name) if can?(current_user, :read_pod_logs, project)

      super.merge(ee_metrics_data)
    end
  end
end
