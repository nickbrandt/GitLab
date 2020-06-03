# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NetworkPolicies::ResourcesService do
  let(:service) { NetworkPolicies::ResourcesService.new(environment: environment) }
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

    it 'returns success response with policies from the deployment namespace' do
      expect(kubeclient).to receive(:get_network_policies).with(namespace: environment.deployment_namespace) { [policy.generate] }
      expect(subject).to be_success
      expect(subject.payload.count).to eq(1)
      expect(subject.payload.first.as_json).to eq(policy.as_json)
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
        allow(kubeclient).to receive(:get_network_policies).and_raise(Kubeclient::HttpError.new(500, 'system failure', nil))
      end

      it 'returns error response' do
        expect(subject).to be_error
        expect(subject.http_status).to eq(:bad_request)
        expect(subject.message).not_to be_nil
      end
    end
  end
end
