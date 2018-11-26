require 'spec_helper'

describe 'Prometheus custom metrics', :js do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let!(:prometheus_metric) { create(:prometheus_metric, project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit(project_settings_integrations_path(project))

    click_link('Prometheus')

    fill_in_prometheus_integration

    click_link('Prometheus')
  end

  def fill_in_prometheus_integration
    check('Active')
    fill_in('API URL', with: 'http://prometheus.example.com')
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
