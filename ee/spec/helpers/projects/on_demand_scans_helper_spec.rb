# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::OnDemandScansHelper do
  describe '#on_demand_scans_data' do
    it 'returns proper data' do
      expect(helper.on_demand_scans_data).to match(
        'help-page-path' => help_page_path('user/application_security/dast/index', anchor: 'on-demand-scans'),
        'empty-state-svg-path' => match_asset_path('/assets/illustrations/empty-state/ondemand-scan-empty.svg')
      )
    end
  end
end
