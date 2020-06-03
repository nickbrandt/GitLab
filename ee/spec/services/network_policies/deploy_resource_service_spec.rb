# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NetworkPolicies::DeployResourceService do
  let(:service) { NetworkPolicies::DeployResourceService.new(policy: policy, environment: environment) }
  let(:environment) { instance_double('Environment', deployment_platform: platform, deployment_namespace: 'namespace') }
  let(:platform) { instance_double('Clusters::Platforms::Kubernetes', kubeclient: kubeclient) }
  let(:kubeclient) { double('Kubeclient::Client') }
  let(:policy) do
    Gitlab::Kubernetes::NetworkPolicy.new(
      name: 'policy',
      namespace: 'another',
      pod_selector: { matchLabels: { role: 'db' } },
      ingress: [{ from: [{ namespaceSelector: { matchLabels: { project: 'myproject' } } }] }]
    )
  end

  describe '#execute' do
    subject { service.execute }

    it 'creates resource in the deployment namespace and return success response with a policy' do
      namespaced_policy = policy.generate
      namespaced_policy[:metadata][:namespace] = environment.deployment_namespace

      expect(kubeclient).to receive(:create_network_policy).with(namespaced_policy) { policy.generate }
      expect(subject).to be_success
      expect(subject.payload.as_json).to eq(policy.as_json)
    end

    context 'with resource_name' do
      let(:service) { NetworkPolicies::DeployResourceService.new(policy: policy, environment: environment, resource_name: 'policy2') }

      it 'updates resource in the deployment namespace and returns success response with a policy' do
        namespaced_policy = policy.generate
        namespaced_policy[:metadata][:namespace] = environment.deployment_namespace
        namespaced_policy[:metadata][:name] = 'policy2'

        expect(kubeclient).to receive(:update_network_policy).with(namespaced_policy) { policy.generate }
        expect(subject).to be_success
        expect(subject.payload.as_json).to eq(policy.as_json)
      end
    end

    context 'without policy' do
      let(:policy) { nil }

      it 'returns error response' do
        expect(subject).to be_error
        expect(subject.http_status).to eq(:bad_request)
        expect(subject.message).not_to be_nil
      end
    end

    context 'without deployment_platform' do
      let(:platform) { nil }

      it 'returns error response' do
        expect(subject).to be_error
        expect(subject.http_status).to eq(:bad_request)
        expect(subject.message).not_to be_nil
      end
    end

    context 'with Kubeclient::HttpError' do
      before do
        allow(kubeclient).to receive(:create_network_policy).and_raise(Kubeclient::HttpError.new(500, 'system failure', nil))
      end

      it 'returns error response' do
        expect(subject).to be_error
        expect(subject.http_status).to eq(:bad_request)
        expect(subject.message).not_to be_nil
      end
    end
  end
end
