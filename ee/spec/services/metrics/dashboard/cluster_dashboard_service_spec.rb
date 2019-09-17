# frozen_string_literal: true

require 'spec_helper'

describe Metrics::Dashboard::ClusterDashboardService, :use_clean_rails_memory_store_caching do
  include MetricsDashboardHelpers

  set(:user) { create(:user) }
  set(:cluster_project) { create(:cluster_project) }
  set(:cluster) { cluster_project.cluster }
  set(:project) { cluster_project.project }

  before do
    project.add_maintainer(user)
  end

  describe 'get_dashboard' do
    let(:dashboard_path) { described_class::CLUSTER_DASHBOARD_PATH }
    let(:service_params) { [project, user, { cluster: cluster, cluster_type: :project, dashboard_path: dashboard_path }] }
    let(:service_call) { described_class.new(*service_params).get_dashboard }

    it_behaves_like 'valid dashboard service response'

    it 'caches the unprocessed dashboard for subsequent calls' do
      expect(YAML).to receive(:safe_load).once.and_call_original

      described_class.new(*service_params).get_dashboard
      described_class.new(*service_params).get_dashboard
    end

    context 'when called with a non-system dashboard' do
      let(:dashboard_path) { 'garbage/dashboard/path' }

      # We want to always return the cluster dashboard.
      it_behaves_like 'valid dashboard service response'
    end
  end
end
