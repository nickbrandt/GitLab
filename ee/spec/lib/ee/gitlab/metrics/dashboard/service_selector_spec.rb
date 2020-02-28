# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::Dashboard::ServiceSelector do
  include MetricsDashboardHelpers

  describe '#call' do
    subject { described_class.call(arguments) }

    context 'when cluster is provided' do
      let(:arguments) { { cluster: "some cluster" } }

      it { is_expected.to be Metrics::Dashboard::ClusterDashboardService }
    end

    context 'when metrics embed is for an alert' do
      let(:arguments) { { embedded: true, prometheus_alert_id: 5 } }

      it { is_expected.to be Metrics::Dashboard::GitlabAlertEmbedService }
    end
  end
end
