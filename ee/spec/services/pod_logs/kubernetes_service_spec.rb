# frozen_string_literal: true

require 'spec_helper'

describe ::PodLogs::KubernetesService do
  include KubernetesHelpers

  let_it_be(:environment, refind: true) { create(:environment) }

  let(:pod_name) { 'pod-1' }
  let(:container_name) { 'container-1' }
  let(:params) { {} }

  let(:raw_logs) do
    "2019-12-13T14:04:22.123456Z Log 1\n2019-12-13T14:04:23.123456Z Log 2\n" \
      "2019-12-13T14:04:24.123456Z Log 3"
  end

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

    let(:expected_logs) { raw_logs }
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

  describe '#force_logs_encoding_to_utf8' do
    let(:service) { create(:cluster_platform_kubernetes, :configured) }
    let(:expected_logs) { '2019-12-13T14:04:22.123456Z ✔ Started logging errors to Sentry' }
    let(:raw_logs) { expected_logs.dup.force_encoding(Encoding::ASCII_8BIT) }

    let(:result_arg) do
      {
        pod_name: pod_name,
        container_name: container_name,
        logs: raw_logs
      }
    end

    before do
      stub_kubeclient_discover(service.api_url)

      logs_url = service.api_url +
        "/api/v1/namespaces/#{environment.deployment_namespace}/pods/#{pod_name}" \
        "/log?container=#{container_name}&tailLines=#{PodLogs::KubernetesService::LOGS_LIMIT}&" \
        "timestamps=true"

      response = {
        body: raw_logs
      }

      WebMock.stub_request(:get, logs_url).to_return(response)
    end

    it 'converts logs to utf-8' do
      result = subject.send(:force_logs_encoding_to_utf8, result_arg)

      expect(result[:status]).to eq(:success)
      expect(result[:logs]).to eq(expected_logs)
    end

    it 'ignores errors' do
      allow(Gitlab::Utils).to receive(:force_utf8)
        .and_raise(Encoding::UndefinedConversionError, 'error')

      result = subject.send(:force_logs_encoding_to_utf8, result_arg)

      expect(result[:status]).to eq(:success)
      expect(result[:logs]).to eq(raw_logs)
    end

    it 'does not execute if feature flag is disabled' do
      stub_feature_flags(pod_logs_encoding_fix: false)

      result = subject.send(:force_logs_encoding_to_utf8, result_arg)

      expect(result[:status]).to eq(:success)
      expect(result[:logs]).to eq(raw_logs)
      expect(result[:logs].encoding).to eq(Encoding::ASCII_8BIT)
    end

    context 'when logs are already in utf-8' do
      let(:raw_logs) { expected_logs }

      it 'does not execute' do
        result = subject.send(:force_logs_encoding_to_utf8, result_arg)

        expect(result[:status]).to eq(:success)
        expect(result[:logs]).to eq(expected_logs)
      end
    end
  end

  describe '#encode_logs_to_utf8' do
    let(:service) { create(:cluster_platform_kubernetes, :configured) }
    let(:expected_logs) { '2019-12-13T14:04:22.123456Z ✔ Started logging errors to Sentry' }
    let(:raw_logs) { expected_logs.dup.force_encoding(Encoding::ASCII_8BIT) }

    let(:result_arg) do
      {
        pod_name: pod_name,
        container_name: container_name,
        logs: raw_logs
      }
    end

    before do
      stub_kubeclient_discover(service.api_url)

      logs_url = service.api_url +
        "/api/v1/namespaces/#{environment.deployment_namespace}/pods/#{pod_name}" \
        "/log?container=#{container_name}&tailLines=#{PodLogs::KubernetesService::LOGS_LIMIT}&" \
        "timestamps=true"

      response = {
        body: raw_logs
      }

      WebMock.stub_request(:get, logs_url).to_return(response)
    end

    it 'encodes logs to utf-8' do
      result = subject.send(:encode_logs_to_utf8, result_arg)

      expect(result[:status]).to eq(:success)
      expect(result[:logs].encoding).to eq(Encoding::UTF_8)
    end

    it 'does not execute if feature flag is disabled' do
      stub_feature_flags(pod_logs_encoding_fix: false)

      result = subject.send(:encode_logs_to_utf8, result_arg)

      expect(result[:status]).to eq(:success)
      expect(result[:logs]).to eq(raw_logs)
      expect(result[:logs].encoding).to eq(Encoding::ASCII_8BIT)
    end

    it 'returns error if exception is raised' do
      allow(result_arg[:logs]).to receive(:encode).and_raise(EncodingError, 'error')

      result = subject.send(:encode_logs_to_utf8, result_arg)

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Kubernetes logs could not be converted into UTF-8. Check Gitlab logs for errors.')
    end

    context 'when logs are already in utf-8' do
      let(:raw_logs) { expected_logs }

      it 'does not execute' do
        result = subject.send(:encode_logs_to_utf8, result_arg)

        expect(result[:status]).to eq(:success)
        expect(result[:logs]).to eq(expected_logs)
      end
    end
  end

  describe '#split_logs' do
    let(:result_arg) do
      {
        pod_name: pod_name,
        container_name: container_name,
        logs: raw_logs
      }
    end

    let(:service) { create(:cluster_platform_kubernetes, :configured) }

    before do
      create(:cluster, :provided_by_gcp, environment_scope: '*', projects: [environment.project])
      create(:deployment, :success, environment: environment)

      stub_kubeclient_logs(pod_name, environment.deployment_namespace, container: container_name)
    end

    it 'returns the logs' do
      result = subject.send(:split_logs, result_arg)

      expect(result[:status]).to eq(:success)
      expect(result[:logs]).to eq(expected_logs)
    end
  end
end
