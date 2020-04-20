# frozen_string_literal: true

module Projects::SurfaceAlertsHelper
  def surface_alerts_data(project)
    {
      'index-path' => project_surface_alerts_path(project,
                                                        format: :json),
      'enable-surface-alerts-path' => project_settings_operations_path(project),
      'empty-alert-svg-path' => image_path('illustrations/alert-management-empty-state.svg')
    }
  end
end
