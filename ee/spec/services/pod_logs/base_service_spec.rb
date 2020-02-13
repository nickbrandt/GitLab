# frozen_string_literal: true

require 'spec_helper'

describe ::PodLogs::BaseService do
  include KubernetesHelpers

  let_it_be(:environment, refind: true) { create(:environment) }

  let(:pod_name) { 'pod-1' }
  let(:container_name) { 'container-0' }
  let(:params) { {} }
  let(:raw_pods) do
    JSON.parse([
      kube_pod(name: pod_name)
    ].to_json, object_class: OpenStruct)
  end

  subject { described_class.new(environment, params: params) }

  describe '#initialize' do
    let(:params) do
      {
        'container_name' => container_name,
        'another_param' => 'foo'
      }
    end

    it 'filters the parameters' do
      expect(subject.environment).to eq(environment)
      expect(subject.params).to eq({
        'container_name' => container_name
      })
      expect(subject.params.equal?(params)).to be(false)
    end
  end

  describe '#check_param_lengths' do
    context 'when pod_name and container_name are provided' do
      let(:params) do
        {
          'pod_name' => pod_name,
          'container_name' => container_name
        }
      end

      it 'returns success' do
        result = subject.send(:check_param_lengths, {})

        expect(result[:status]).to eq(:success)
        expect(result[:pod_name]).to eq(pod_name)
        expect(result[:container_name]).to eq(container_name)
      end
    end

    context 'when pod_name is too long' do
      let(:params) do
        {
        'pod_name' => "a very long string." * 15
      }
      end

      it 'returns an error' do
        result = subject.send(:check_param_lengths, {})

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('pod_name cannot be larger than 253 chars')
      end
    end

    context 'when container_name is too long' do
      let(:params) do
        {
          'container_name' => "a very long string." * 15
        }
      end

      it 'returns an error' do
        result = subject.send(:check_param_lengths, {})

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('container_name cannot be larger than 253 chars')
      end
    end
  end

  describe '#check_deployment_platform' do
    it 'returns success when deployment platform exist' do
      create(:cluster, :provided_by_gcp, environment_scope: '*', projects: [environment.project])
      create(:deployment, :success, environment: environment)

      result = subject.send(:check_deployment_platform, {})

      expect(result[:status]).to eq(:success)
    end

    it 'returns error when deployment platform does not exist' do
      result = subject.send(:check_deployment_platform, {})

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('No deployment platform available')
    end
  end

  describe '#get_raw_pods' do
    let(:service) { create(:cluster_platform_kubernetes, :configured) }

    it 'returns success with passthrough k8s response' do
      create(:cluster, :provided_by_gcp, environment_scope: '*', projects: [environment.project])
      create(:deployment, :success, environment: environment)
      stub_kubeclient_pods(environment.deployment_namespace)

      result = subject.send(:get_raw_pods, {})

      expect(result[:status]).to eq(:success)
      expect(result[:raw_pods].first).to be_a(Kubeclient::Resource)
    end
  end

  describe '#get_pod_names' do
    it 'returns success with a list of pods' do
      result = subject.send(:get_pod_names, raw_pods: raw_pods)

      expect(result[:status]).to eq(:success)
      expect(result[:pods]).to eq([pod_name])
    end
  end

  describe '#check_pod_name' do
    it 'returns success if pod_name was specified' do
      result = subject.send(:check_pod_name, pod_name: pod_name, pods: [pod_name])

      expect(result[:status]).to eq(:success)
      expect(result[:pod_name]).to eq(pod_name)
    end

    it 'returns success if pod_name was not specified but there are pods' do
      result = subject.send(:check_pod_name, pod_name: nil, pods: [pod_name])

      expect(result[:status]).to eq(:success)
      expect(result[:pod_name]).to eq(pod_name)
    end

    it 'returns error if pod_name was not specified and there are no pods' do
      result = subject.send(:check_pod_name, pod_name: nil, pods: [])

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('No pods available')
    end

    it 'returns error if pod_name was specified but does not exist' do
      result = subject.send(:check_pod_name, pod_name: 'another_pod', pods: [pod_name])

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Pod does not exist')
    end
  end

  describe '#check_container_name' do
    it 'returns success if container_name was specified' do
      result = subject.send(:check_container_name,
        container_name: container_name,
        pod_name: pod_name,
        raw_pods: raw_pods
      )

      expect(result[:status]).to eq(:success)
      expect(result[:container_name]).to eq(container_name)
    end

    it 'returns success if container_name was not specified and there are containers' do
      result = subject.send(:check_container_name,
        pod_name: pod_name,
        raw_pods: raw_pods
      )

      expect(result[:status]).to eq(:success)
      expect(result[:container_name]).to eq(container_name)
    end

    it 'returns error if container_name was not specified and there are no containers on the pod' do
      raw_pods.first.spec.containers = []

      result = subject.send(:check_container_name,
        pod_name: pod_name,
        raw_pods: raw_pods
      )

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('No containers available')
    end

    it 'returns error if container_name was specified but does not exist' do
      result = subject.send(:check_container_name,
        container_name: 'foo',
        pod_name: pod_name,
        raw_pods: raw_pods
      )

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Container does not exist')
    end
  end

  describe '#reactive_cache_updated' do
    context 'get_pod_log' do
      let(:cache_key) { 'get_pod_log' }

      it 'expires k8s_pod_logs etag cache' do
        expected_path = "/root/autodevops-deploy/-/logs/k8s.json"
        allow(subject).to receive(:etag_path).and_return(expected_path)

        allow_next_instance_of(Gitlab::EtagCaching::Store) do |store|
          allow(store).to receive(:touch).with(expected_path).and_call_original
        end

        subject.reactive_cache_updated(cache_key, {})
      end
    end
  end
end
