# frozen_string_literal: true

module Projects::SurfaceAlertsHelper
  def surface_alerts_data(project)
    surface_alerts_enabled = !!project.surface_alerts_setting&.enabled?

    {
      'index-path' => project_surface_alerts_index_path(project,
                                                        format: :json),
      'enable-surface-alerts-link' => project_settings_operations_path(project),
      'surface-alerts-enabled' => surface_alerts_enabled.to_s,
      'illustration-path' => image_path('illustrations/alert-management-empty-state.svg')
    }
  end
end
