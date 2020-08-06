# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Importer do
  include MetricsDashboardHelpers

  describe '.execute' do
    let_it_be(:dashboard_path) { '.gitlab/dashboards/sample_dashboard.yml' }
    let_it_be(:dashboard_hash) { load_sample_dashboard }
    let_it_be(:project) { create(:project) }

    subject { described_class.new(dashboard_path, project) }

    before do
      allow(subject).to receive(:dashboard_hash).and_return(dashboard_hash)
    end

    it 'imports metrics to database' do
      expect { subject.execute }
        .to change { PrometheusMetric.count }.from(0).to(3)
    end
  end

  describe '.execute!' do
    let_it_be(:dashboard_path) { '.gitlab/dashboards/sample_dashboard.yml' }
    let_it_be(:project) { create(:project) }

    subject { described_class.new(dashboard_path, project) }

    before do
      allow(subject).to receive(:dashboard_hash).and_return(dashboard_hash)
    end

    context 'invalid dashboard hash' do
      let(:dashboard_hash) { {} }

      it 'raises error' do
        expect { subject.execute! }.to raise_error(Gitlab::Metrics::Dashboard::Validator::Errors::SchemaValidationError,
          'root is missing required keys: dashboard, panel_groups')
      end
    end
  end
end
