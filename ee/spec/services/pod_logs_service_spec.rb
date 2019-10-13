# frozen_string_literal: true

require 'spec_helper'

describe PodLogsService do
  include KubernetesHelpers
  include ReactiveCachingHelpers

  describe '#execute' do
    let(:environment) { create(:environment, name: 'production') }
    let(:project) { environment.project }
    let(:pod_name) { 'pod-1' }
    let(:container_name) { 'container-1' }
    let(:logs) { ['Log 1', 'Log 2', 'Log 3'] }
    let(:result) { subject.execute }

    let(:params) do
      ActionController::Parameters.new(
        {
          'pod_name' => pod_name,
          'container_name' => container_name
        }
      ).permit!
    end

    subject { described_class.new(environment, params: params) }

    shared_examples 'success' do |message|
      it do
        expect(result[:status]).to eq(:success)
        expect(result[:logs]).to eq(logs)
      end
    end

    shared_examples 'error' do |message|
      it do
        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq(message)
      end
    end

    shared_context 'return error' do |message|
      before do
        allow_any_instance_of(EE::Clusters::Platforms::Kubernetes).to receive(:read_pod_logs)
          .with(pod_name, environment.deployment_namespace, container: container_name)
          .and_return({ status: :error, error: message })
      end
    end

    shared_context 'return success' do
      before do
        allow_any_instance_of(EE::Clusters::Platforms::Kubernetes).to receive(:read_pod_logs)
          .with(pod_name, environment.deployment_namespace, container: container_name)
          .and_return({ status: :success, logs: "Log 1\nLog 2\nLog 3" })
      end
    end

    shared_context 'deployment platform' do
      before do
        create(:cluster, :provided_by_gcp,
          environment_scope: '*', projects: [project])

        allow_any_instance_of(EE::Clusters::Platforms::Kubernetes).to receive(:read_pod_logs)
          .with(pod_name, environment.deployment_namespace, container: container_name)
          .and_return(kube_logs_body)
      end
    end

    context 'when pod name is too large' do
      let(:pod_name) { '1' * 254 }

      it_behaves_like 'error', 'pod_name cannot be larger than 253 chars'
    end

    context 'when container name is too large' do
      let(:container_name) { '1' * 254 }

      it_behaves_like 'error', 'container_name cannot be larger than 253 chars'
    end

    context 'without deployment platform' do
      it_behaves_like 'error', 'No deployment platform'
    end

    context 'with deployment platform' do
      include_context 'deployment platform'

      context 'when pod does not exist' do
        include_context 'return error', 'Pod not found'

        it_behaves_like 'error', 'Pod not found'
      end

      context 'when container_name is specified' do
        include_context 'return success'

        it_behaves_like 'success'
      end

      context 'when container_name is not specified' do
        let(:container_name) { nil }

        let(:params) do
          ActionController::Parameters.new(
            {
              'pod_name' => pod_name,
              'container_name' => nil
            }
          ).permit!
        end

        include_context 'return success'

        it_behaves_like 'success'
      end

      context 'when pod_name is not specified' do
        let(:pod_name) { '' }
        let(:container_name) { nil }
        let(:first_pod_name) { 'some-pod' }

        before do
          create(:deployment, :success, environment: environment)
          allow_any_instance_of(Gitlab::Kubernetes::RolloutStatus).to receive(:instances)
            .and_return([{ pod_name: first_pod_name }])

          allow_any_instance_of(EE::Clusters::Platforms::Kubernetes).to receive(:read_pod_logs)
            .with(first_pod_name, environment.deployment_namespace, container: nil)
            .and_return({ status: :success, logs: "Log 1\nLog 2\nLog 3" })
        end

        it_behaves_like 'success'

        it 'returns logs of first pod' do
          expect_any_instance_of(EE::Clusters::Platforms::Kubernetes).to receive(:read_pod_logs)
            .with(first_pod_name, environment.deployment_namespace, container: nil)

          subject.execute
        end
      end

      context 'when error is returned' do
        include_context 'return error', 'Kubernetes API returned status code: 400'

        it_behaves_like 'error', 'Kubernetes API returned status code: 400'
      end

      context 'when nil is returned' do
        before do
          allow_any_instance_of(EE::Clusters::Platforms::Kubernetes).to receive(:read_pod_logs)
            .with(pod_name, environment.deployment_namespace, container: container_name)
            .and_return(nil)
        end

        it 'returns nil' do
          expect(result).to eq(nil)
        end
      end
    end
  end
end
