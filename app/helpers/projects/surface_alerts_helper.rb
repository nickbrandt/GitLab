# frozen_string_literal: true

module Projects::SurfaceAlertsHelper
  def surface_alerts_data(project)
    {
      'index-path' => project_surface_alerts_path(project,
                                                        format: :json),
      'enable-surface-alerts-link' => project_settings_operations_path(project),
      'illustration-path' => image_path('illustrations/alert-management-empty-state.svg')
    }
  end
end
