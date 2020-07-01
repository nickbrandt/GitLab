# frozen_string_literal: true

RSpec.shared_examples_for 'GET #metrics_dashboard correctly formatted response' do
  it 'returns a json object with the correct keys' do
    get :metrics_dashboard, params: metrics_dashboard_req_params, format: :json

    # Exlcude `all_dashboards` to handle separately.
    found_keys = json_response.keys - ['all_dashboards']

    expect(response).to have_gitlab_http_status(status_code)
    expect(found_keys).to contain_exactly(*expected_keys)
  end
end

RSpec.shared_examples_for 'GET #metrics_dashboard for dashboard' do |dashboard_name|
  let(:expected_keys) { %w(dashboard status metrics_data) }
  let(:status_code) { :ok }

  it_behaves_like 'GET #metrics_dashboard correctly formatted response'

  it 'returns correct dashboard' do
    get :metrics_dashboard, params: metrics_dashboard_req_params, format: :json

    expect(json_response['dashboard']['dashboard']).to eq(dashboard_name)
  end
end
