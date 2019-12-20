# frozen_string_literal: true

require 'spec_helper'

describe Prometheus::AdapterService do
  let_it_be(:project) { create(:project) }
  let_it_be(:cluster, reload: true) { create(:cluster, :provided_by_user, environment_scope: '*', projects: [project]) }

  subject { described_class.new(project, cluster) }

  shared_examples 'adapter service with a deployment-based argument passed in' do
    subject { described_class.new(project, deployment) }

    it 'becomes the deployment platform attribute' do
      expect(subject.deployment_platform).to eq deployment
    end

    context 'when a cluster is tied to the deployment_platform' do
      it 'provides a cluster prometheus adapter' do
        allow(deployment).to receive(:cluster).and_return(cluster)

        expect(subject.cluster_prometheus_adapter).to eq(cluster.application_prometheus)
      end
    end

    context 'when there is no cluster tied to the deployment platform' do
      it 'is nil' do
        allow(deployment).to receive(:cluster).and_return(nil)

        expect(subject.cluster_prometheus_adapter).to be_nil
      end
    end
  end

  describe '#prometheus_adapter' do
    context 'prometheus service can execute queries' do
      let(:prometheus_service) { double(:prometheus_service, can_query?: true) }

      before do
        allow(project).to receive(:find_or_initialize_service).with('prometheus').and_return prometheus_service
      end

      it 'return prometheus service as prometheus adapter' do
        expect(subject.prometheus_adapter).to eq(prometheus_service)
      end
    end

    context "prometheus service can't execute queries" do
      let(:prometheus_service) { double(:prometheus_service, can_query?: false) }

      context 'with cluster with prometheus not available' do
        let!(:prometheus) { create(:clusters_applications_prometheus, :installable, cluster: cluster) }

        it 'returns nil' do
          expect(subject.prometheus_adapter).to be_nil
        end
      end

      context 'with cluster with prometheus available' do
        let!(:prometheus) { create(:clusters_applications_prometheus, :installed, cluster: cluster) }

        it 'returns application handling all environments' do
          expect(subject.prometheus_adapter).to eq(prometheus)
        end
      end

      context 'with cluster without prometheus installed' do
        it 'returns nil' do
          expect(subject.prometheus_adapter).to be_nil
        end
      end
    end

    it_behaves_like 'adapter service with a deployment-based argument passed in' do
      let(:deployment) { project.deployment_platform }
    end

    it_behaves_like 'adapter service with a deployment-based argument passed in' do
      let(:deployment) { create(:deployment, environment: create(:environment, project: project)) }
    end
  end
end
