# frozen_string_literal: true

module OperationsHelper
  def operations_data
    {
      'add-path' => add_operations_project_path,
      'list-path' => operations_list_path,
      'empty-dashboard-svg-path' => image_path('illustrations/operations-dashboard_empty.svg')
    }
  end
end
