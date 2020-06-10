# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NetworkPolicies::DeleteResourceService do
  let(:service) { NetworkPolicies::DeleteResourceService.new(resource_name: 'policy', environment: environment) }
  let(:environment) { instance_double('Environment', deployment_platform: platform, deployment_namespace: 'namespace') }
  let(:platform) { instance_double('Clusters::Platforms::Kubernetes', kubeclient: kubeclient) }
  let(:kubeclient) { double('Kubeclient::Client') }

  describe '#execute' do
    subject { service.execute }

    it 'deletes resource from the deployment namespace and returns success response' do
      expect(kubeclient).to receive(:delete_network_policy).with('policy', environment.deployment_namespace)
      expect(subject).to be_success
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
        allow(kubeclient).to receive(:delete_network_policy).and_raise(Kubeclient::HttpError.new(500, 'system failure', nil))
      end

      it 'returns error response' do
        expect(subject).to be_error
        expect(subject.http_status).to eq(:bad_request)
        expect(subject.message).not_to be_nil
      end
    end
  end
end
