# frozen_string_literal: true

require 'spec_helper'

describe ::PodLogs::KubernetesService do
  include KubernetesHelpers

  let_it_be(:environment, refind: true) { create(:environment) }

  let(:pod_name) { 'pod-1' }
  let(:container_name) { 'container-1' }
  let(:params) { {} }
  let(:expected_logs) do
    [
      { message: "Log 1", timestamp: "2019-12-13T14:04:22.123456Z" },
      { message: "Log 2", timestamp: "2019-12-13T14:04:23.123456Z" },
      { message: "Log 3", timestamp: "2019-12-13T14:04:24.123456Z" }
    ]
  end

  subject { described_class.new(environment, params: params) }

  describe '#pod_logs' do
    let(:result_arg) do
      {
        pod_name: pod_name,
        container_name: container_name
      }
    end
    let(:service) { create(:cluster_platform_kubernetes, :configured) }

    before do
      create(:cluster, :provided_by_gcp, environment_scope: '*', projects: [environment.project])
      create(:deployment, :success, environment: environment)
    end

    it 'returns the logs' do
      stub_kubeclient_logs(pod_name, environment.deployment_namespace, container: container_name)

      result = subject.send(:pod_logs, result_arg)

      expect(result[:status]).to eq(:success)
      expect(result[:logs]).to eq(expected_logs)
    end

    it 'handles Not Found errors from k8s' do
      allow_any_instance_of(Gitlab::Kubernetes::KubeClient)
        .to receive(:get_pod_log)
        .with(any_args)
        .and_raise(Kubeclient::ResourceNotFoundError.new(404, 'Not Found', {}))

      result = subject.send(:pod_logs, result_arg)

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Pod not found')
    end

    it 'handles HTTP errors from k8s' do
      allow_any_instance_of(Gitlab::Kubernetes::KubeClient)
        .to receive(:get_pod_log)
        .with(any_args)
        .and_raise(Kubeclient::HttpError.new(500, 'Error', {}))

      result = subject.send(:pod_logs, result_arg)

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Kubernetes API returned status code: 500')
    end
  end
end
