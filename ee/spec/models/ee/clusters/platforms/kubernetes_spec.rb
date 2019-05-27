require 'spec_helper'

describe Clusters::Platforms::Kubernetes, :use_clean_rails_memory_store_caching do
  include KubernetesHelpers
  include ReactiveCachingHelpers

  describe '#calculate_reactive_cache' do
    subject { service.calculate_reactive_cache }

    let(:cluster) { create(:cluster, :project, enabled: true, platform_kubernetes: service) }
    let(:service) { create(:cluster_platform_kubernetes, :configured) }
    let(:namespace) { cluster.kubernetes_namespace_for(cluster.first_project) }

    context 'when kubernetes responds with valid pods and deployments' do
      before do
        stub_kubeclient_pods(namespace)
        stub_kubeclient_deployments(namespace)
      end

      it { is_expected.to eq(pods: [kube_pod], deployments: [kube_deployment]) }

      context 'on a cluster that is not project level' do
        let(:cluster) { create(:cluster, :group, platform_kubernetes: service) }

        it { is_expected.to eq(pods: [], deployments: []) }
      end
    end

    context 'when kubernetes responds with 404s' do
      before do
        stub_kubeclient_pods(namespace, status: 404)
        stub_kubeclient_deployments(namespace, status: 404)
      end

      it { is_expected.to eq(pods: [], deployments: []) }
    end
  end

  describe '#read_pod_logs' do
    subject { service.read_pod_logs(pod_name) }

    let(:pod_name) { 'foo' }
    let(:cluster) { create(:cluster, :project, enabled: true, platform_kubernetes: service) }
    let(:service) { create(:cluster_platform_kubernetes, :configured) }
    let(:namespace) { cluster.kubernetes_namespace_for(cluster.first_project) }

    context 'when kubernetes responds with valid logs' do
      before do
        stub_kubeclient_logs(pod_name, namespace)
      end

      it 'returns logs' do
        expect(subject.body).to eq("\"Log 1\\nLog 2\\nLog 3\"")
      end

      context 'on a cluster that is not project level' do
        let(:cluster) { create(:cluster, :group, platform_kubernetes: service) }

        it { is_expected.to be_empty }
      end
    end

    context 'when kubernetes response with 500s' do
      before do
        stub_kubeclient_logs(pod_name, namespace, status: 500)
      end

      it { expect { subject }.to raise_error(::Kubeclient::HttpError) }
    end

    context 'when kubernetes responds with 404s' do
      before do
        stub_kubeclient_logs(pod_name, namespace, status: 404)
      end

      it { is_expected.to be_empty }
    end
  end
end
