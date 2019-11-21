# frozen_string_literal: true

module OperationsHelper
  def operations_data
    {
      'add-path' => add_operations_project_path,
      'list-path' => operations_list_path,
      'empty-dashboard-svg-path' => image_path('illustrations/operations-dashboard_empty.svg'),
      'empty-dashboard-help-path' => help_page_path('user/operations_dashboard/index.html')
    }
  end

  def environments_data
    {
      'add-path' => add_operations_project_path,
      'list-path' => operations_environments_list_path,
      'empty-dashboard-svg-path' => image_path('illustrations/operations-dashboard_empty.svg'),
      'empty-dashboard-help-path' => help_page_path('ci/environments/environments_dashboard.html')
    }
  end
end
