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

    fill_in_prometheus_integration

    click_link('Prometheus')
  end

  def fill_in_prometheus_integration
    check('Active')
    fill_in('API URL', with: 'https://prometheus.example.com')
    click_button('Save changes')
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
