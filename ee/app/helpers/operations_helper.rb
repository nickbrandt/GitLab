# frozen_string_literal: true

module OperationsHelper
  def operations_data
    {
      'add-path' => add_operations_project_path,
      'list-path' => operations_list_path,
      'empty-dashboard-svg-path' => image_path('illustrations/operations-dashboard_empty.svg'),
      'empty-dashboard-help-path' => help_page_path('user/operations_dashboard/index.md')
    }
  end

  def environments_data
    {
      'add-path' => add_operations_project_path,
      'list-path' => operations_environments_list_path,
      'empty-dashboard-svg-path' => image_path('illustrations/operations-dashboard_empty.svg'),
      'empty-dashboard-help-path' => help_page_path('ci/environments/environments_dashboard.md'),
      'environments-dashboard-help-path' => help_page_path('ci/environments/environments_dashboard.md')
    }
  end

  def status_page_settings_data(status_page_setting)
    {
      'user-can-enable-status-page' => can?(current_user, :admin_operations, @project).to_s,
      'setting-enabled' => status_page_setting&.enabled?.to_s,
      'setting-aws-access-key' => status_page_setting&.aws_access_key,
      'setting-masked-aws-secret-key' => status_page_setting&.masked_aws_secret_key,
      'setting-aws-region' => status_page_setting&.aws_region,
      'setting-aws-s3-bucket-name' => status_page_setting&.aws_s3_bucket_name
    }
  end
end
