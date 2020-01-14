# frozen_string_literal: true

require 'spec_helper'

describe PodLogsService do
  include KubernetesHelpers
  include ReactiveCachingHelpers

  describe '#execute' do
    let(:environment) { create(:environment, name: 'production') }
    let(:project) { environment.project }
    let(:pod_name) { 'pod-1' }
    let(:response_pod_name) { pod_name }
    let(:pods) { [pod_name] }
    let(:container_name) { 'container-1' }
    let(:search) { nil }
    let(:enable_advanced_querying) { false }
    let(:logs) { ['Log 1', 'Log 2', 'Log 3'] }
    let(:result) { subject.execute }

    let(:params) do
      ActionController::Parameters.new(
        {
          'pod_name' => pod_name,
          'container_name' => container_name,
          'search' => search
        }
      ).permit!
    end

    subject { described_class.new(environment, params: params) }

    shared_examples 'success' do |message|
      it do
        expect(result[:status]).to eq(:success)
        expect(result[:logs]).to eq(logs)
        expect(result[:pods]).to eq(pods)
        expect(result[:pod_name]).to eq(response_pod_name)
        expect(result[:container_name]).to eq(container_name)
        expect(result[:enable_advanced_querying]).to eq(enable_advanced_querying)
      end
    end

    shared_examples 'error' do |message|
      it do
        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq(message)
      end
    end

    shared_examples 'returns pod_name and container_name' do
      it do
        expect(result[:pod_name]).to eq(response_pod_name)
        expect(result[:container_name]).to eq(container_name)
      end
    end

    shared_context 'return error' do |message|
      before do
        allow_any_instance_of(EE::Clusters::Platforms::Kubernetes).to receive(:read_pod_logs)
          .with(environment.id, pod_name, environment.deployment_namespace, container: container_name, search: search)
          .and_return({
            status: :error,
            error: message,
            pod_name: response_pod_name,
            container_name: container_name,
            enable_advanced_querying: enable_advanced_querying
          })
      end
    end

    shared_context 'return success' do
      before do
        allow_any_instance_of(EE::Clusters::Platforms::Kubernetes).to receive(:read_pod_logs)
          .with(environment.id, response_pod_name, environment.deployment_namespace, container: container_name, search: search)
          .and_return({
            status: :success,
            logs: ["Log 1", "Log 2", "Log 3"],
            pod_name: response_pod_name,
            container_name: container_name,
            enable_advanced_querying: enable_advanced_querying
          })
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
      it_behaves_like 'error', 'No deployment platform available'
    end

    context 'with deployment platform' do
      let(:rollout_status) do
        instance_double(::Gitlab::Kubernetes::RolloutStatus, instances: [{ pod_name: response_pod_name }])
      end

      before do
        create(:cluster, :provided_by_gcp,
          environment_scope: '*', projects: [project])

        create(:deployment, :success, environment: environment)
        allow(environment).to receive(:rollout_status_with_reactive_cache)
          .and_return(rollout_status)
      end

      context 'when pod does not exist' do
        include_context 'return error', 'Pod not found'

        it_behaves_like 'error', 'Pod not found'

        it_behaves_like 'returns pod_name and container_name'
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
        let(:pods) { [first_pod_name] }
        let(:response_pod_name) { first_pod_name }

        include_context 'return success'

        it_behaves_like 'success'

        it 'returns logs of first pod' do
          expect_any_instance_of(EE::Clusters::Platforms::Kubernetes).to receive(:read_pod_logs)
            .with(environment.id, first_pod_name, environment.deployment_namespace, container: nil, search: search)

          subject.execute
        end

        context 'when there are no pods' do
          let(:rollout_status) { instance_double(::Gitlab::Kubernetes::RolloutStatus, instances: []) }

          it 'returns error' do
            expect(result[:status]).to eq(:error)
            expect(result[:message]).to eq('No pods available')
          end
        end

        context 'when rollout_status cache is empty' do
          before do
            allow(environment).to receive(:rollout_status_with_reactive_cache)
              .and_return(nil)
          end

          it 'returns nil' do
            expect(subject.execute).to eq(status: :processing, last_step: :check_pod_names)
          end
        end
      end

      context 'when search is specified' do
        let(:pod_name) { 'some-pod' }
        let(:container_name) { nil }
        let(:search) { 'foo +bar' }

        include_context 'return success'

        it_behaves_like 'success'
      end

      context 'when error is returned' do
        include_context 'return error', 'Kubernetes API returned status code: 400'

        it_behaves_like 'error', 'Kubernetes API returned status code: 400'

        it_behaves_like 'returns pod_name and container_name'
      end

      context 'when nil is returned' do
        before do
          allow_any_instance_of(EE::Clusters::Platforms::Kubernetes).to receive(:read_pod_logs)
            .with(environment.id, pod_name, environment.deployment_namespace, container: container_name, search: search)
            .and_return(nil)
        end

        it 'returns processing' do
          expect(result).to eq(status: :processing, last_step: :pod_logs)
        end
      end
    end
  end
end
