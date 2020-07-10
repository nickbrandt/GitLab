# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::InlineMetricsFilter do
  include FilterSpecHelper

  let(:params) { %w(foo bar) }
  let(:query_params) { {} }

  let(:trigger_url) { urls.namespace_project_metrics_url(*params, query_params) }
  let(:dashboard_url) { urls.namespace_project_metrics_dashboard_url(*params, **query_params, embedded: true) }

  it_behaves_like 'a metrics embed filter'

  context 'with query params specified' do
    let(:query_params) do
      {
        dashboard: 'config/prometheus/common_metrics.yml',
        group: 'System metrics (Kubernetes)',
        title: 'Core Usage (Pod Average)',
        y_label: 'Cores per Pod',
        env_id: 12
      }
    end

    it_behaves_like 'a metrics embed filter'
  end

  it 'leaves links to other dashboards unchanged' do
    url = urls.namespace_project_grafana_api_metrics_dashboard_url('foo', 'bar')
    input = %(<a href="#{url}">example</a>)

    expect(filter(input).to_s).to eq(input)
  end
end
