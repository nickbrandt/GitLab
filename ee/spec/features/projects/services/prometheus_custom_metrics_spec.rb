# frozen_string_literal: true

require 'spec_helper'

describe 'Prometheus custom metrics', :js do
  include PrometheusHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let!(:prometheus_metric) { create(:prometheus_metric, project: project) }

  around do |example|
    Timecop.freeze { example.run }
  end

  before do
    project.add_maintainer(user)
    sign_in(user)

    stub_licensed_features(custom_prometheus_metrics: true)

    visit(project_settings_integrations_path(project))

    click_link('Prometheus')

    stub_request(:get, prometheus_query_with_time_url('avg(metric)', Time.now.utc))

    create(:prometheus_service, project: project, api_url: 'http://prometheus.example.com', manual_configuration: '1', active: true)

    click_link('Prometheus')
  end

  it 'Deletes a custom metric' do
    wait_for_requests

    first('.custom-metric-link-bold').click

    click_button('Delete')
    click_button('Delete metric')

    wait_for_requests

    expect(all('.custom-metric-link-bold').count).to eq(0)
  end
end
