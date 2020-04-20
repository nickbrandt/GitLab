# frozen_string_literal: true

require 'spec_helper'

describe Projects::SurfaceAlertsHelper do
  include Gitlab::Routing.url_helpers

  let(:project) { create(:project) }

  describe '#surface_alerts_data' do
    let(:setting_path) { project_settings_operations_path(project) }

    let(:index_path) do
      project_surface_alerts_path(project, format: :json)
    end

    context 'without surface_alerts_setting' do
      it 'returns frontend configuration' do
        expect(surface_alerts_data(project)).to eq(
          'index-path' => index_path,
          'enable-surface-alerts-path' => setting_path,
          "empty-alert-svg-path" => "/images/illustrations/alert-management-empty-state.svg"
        )
      end
    end
  end
end
