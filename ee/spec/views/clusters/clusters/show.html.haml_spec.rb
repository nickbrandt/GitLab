# frozen_string_literal: true

require 'spec_helper'

describe 'clusters/clusters/show' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  context 'when the cluster details page is opened' do
    before do
      assign(:cluster, cluster_presenter)
      allow(view).to receive(:clusterable).and_return(clusterable)
    end

    context 'with project level cluster' do
      let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
      let(:clusterable) { ClusterablePresenter.fabricate(project, current_user: user) }
      let(:cluster_presenter) { cluster.present(current_user: user) }

      before do
        stub_licensed_features(cluster_health: true)
      end

      it 'displays the Cluster health section' do
        render

        expect(rendered).to have_selector('#cluster-health')
        expect(rendered).to have_content('Cluster health')
      end
    end

    context 'with group level cluster' do
      let(:cluster) { create(:cluster, :group, :provided_by_gcp) }
      let(:clusterable) { ClusterablePresenter.fabricate(cluster.group, current_user: user) }
      let(:cluster_presenter) { cluster.present(current_user: user) }

      before do
        stub_licensed_features(cluster_health: true)
      end

      it 'does not display cluster health section' do
        render

        expect(rendered).not_to have_selector('#cluster-health')
        expect(rendered).not_to have_content('Cluster health')
      end
    end
  end
end
