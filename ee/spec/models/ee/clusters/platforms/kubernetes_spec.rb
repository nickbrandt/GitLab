require 'spec_helper'

describe Clusters::Platforms::Kubernetes do
  include KubernetesHelpers

  describe '#rollout_status' do
    let(:service) { create(:cluster_platform_kubernetes, :configured) }
    let(:environment) { create(:environment) }
    let(:cache_data) { Hash(deployments: deployments, pods: pods) }
    let(:pods) { [kube_pod] }
    let(:deployments) { [kube_deployment] }
    let(:legacy_deployments) { [kube_deployment] }

    subject { service.rollout_status(environment, cache_data) }

    before do
      allow(service).to receive(:filter_by_project_environment).with(pods, any_args).and_return(pods)
      allow(service).to receive(:filter_by_project_environment).with(deployments, any_args).and_return(deployments)
      allow(service).to receive(:filter_by_legacy_label).with(deployments, any_args).and_return(legacy_deployments)
    end

    it 'requests the rollout status' do
      expect(::Gitlab::Kubernetes::RolloutStatus).to receive(:from_deployments).with(*deployments, pods: pods, legacy_deployments: legacy_deployments)

      subject
    end

    context 'no pod data provided' do
      let(:pods) { [] }

      it 'requests the rollout status without pod information' do
        expect(::Gitlab::Kubernetes::RolloutStatus).to receive(:from_deployments).with(*deployments, pods: nil, legacy_deployments: legacy_deployments)

        subject
      end
    end
  end

  describe '#read_pod_logs' do
    let(:cluster) { create(:cluster, :project, platform_kubernetes: service) }
    let(:service) { create(:cluster_platform_kubernetes, :configured) }
    let(:pod_name) { 'pod-1' }
    let(:namespace) { 'app' }

    subject { service.read_pod_logs(pod_name, namespace) }

    context 'when kubernetes responds with valid logs' do
      before do
        stub_kubeclient_logs(pod_name, namespace)
      end

      shared_examples 'successful log request' do
        it { expect(subject.body).to eq("\"Log 1\\nLog 2\\nLog 3\"") }
      end

      context 'on a project level cluster' do
        let(:cluster) { create(:cluster, :project, platform_kubernetes: service) }

        include_examples 'successful log request'
      end

      context 'on a group level cluster' do
        let(:cluster) { create(:cluster, :group, platform_kubernetes: service) }

        include_examples 'successful log request'
      end

      context 'on an instance level cluster' do
        let(:cluster) { create(:cluster, :instance, platform_kubernetes: service) }

        include_examples 'successful log request'
      end
    end

    context 'when kubernetes responds with 500s' do
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

  describe '#calculate_reactive_cache_for' do
    let(:cluster) { create(:cluster, :project, platform_kubernetes: service) }
    let(:service) { create(:cluster_platform_kubernetes, :configured) }
    let(:namespace) { 'app' }
    let(:environment) { instance_double(Environment, deployment_namespace: namespace) }

    subject { service.calculate_reactive_cache_for(environment) }

    before do
      allow(service).to receive(:read_pods).and_return([])
    end

    context 'when kubernetes responds with valid deployments' do
      before do
        stub_kubeclient_deployments(namespace)
      end

      shared_examples 'successful deployment request' do
        it { is_expected.to include(deployments: [kube_deployment]) }
      end

      context 'on a project level cluster' do
        let(:cluster) { create(:cluster, :project, platform_kubernetes: service) }

        include_examples 'successful deployment request'
      end

      context 'on a group level cluster' do
        let(:cluster) { create(:cluster, :group, platform_kubernetes: service) }

        include_examples 'successful deployment request'
      end

      context 'on an instance level cluster' do
        let(:cluster) { create(:cluster, :instance, platform_kubernetes: service) }

        include_examples 'successful deployment request'
      end
    end

    context 'when kubernetes responds with 500s' do
      before do
        stub_kubeclient_deployments(namespace, status: 500)
      end

      it { expect { subject }.to raise_error(::Kubeclient::HttpError) }
    end

    context 'when kubernetes responds with 404s' do
      before do
        stub_kubeclient_deployments(namespace, status: 404)
      end

      it { is_expected.to include(deployments: []) }
    end
  end
end
