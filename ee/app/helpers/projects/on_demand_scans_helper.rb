# frozen_string_literal: true

module Projects::OnDemandScansHelper
  def on_demand_scans_data
    {
      'help-page-path' => help_page_path('user/application_security/dast/index', anchor: 'on-demand-scans'),
      'empty-state-svg-path' => image_path('illustrations/empty-state/ondemand-scan-empty.svg')
    }
  end
end
