# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::InlineMetricsRedactorFilter do
  include FilterSpecHelper

  let_it_be(:project) { create(:project) }
  let(:input) { %(<div class="js-render-metrics" data-dashboard-url="#{url}"></div>) }
  let(:doc) { filter(input) }

  context 'for an alert embed' do
    let_it_be(:alert) { create(:prometheus_alert, project: project) }
    let(:url) do
      urls.metrics_dashboard_project_prometheus_alert_url(
        project,
        alert.prometheus_metric_id,
        environment_id: alert.environment_id,
        embedded: true
      )
    end

    before do
      stub_licensed_features(prometheus_alerts: true)
    end

    it_behaves_like 'redacts the embed placeholder'
    it_behaves_like 'retains the embed placeholder when applicable'
  end
end
