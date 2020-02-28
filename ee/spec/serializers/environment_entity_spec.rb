# frozen_string_literal: true

require 'spec_helper'

describe EnvironmentEntity do
  include KubernetesHelpers
  include Gitlab::Routing.url_helpers

  let(:user) { create(:user) }
  let(:environment) { create(:environment) }

  before do
    environment.project.add_maintainer(user)
  end

  let(:entity) do
    described_class.new(environment, request: double(current_user: user))
  end

  describe '#as_json' do
    subject { entity.as_json }

    context 'when deploy_boards are available' do
      before do
        stub_licensed_features(deploy_board: true)
      end

      context 'with deployment service ready' do
        before do
          allow(environment).to receive(:has_terminals?).and_return(true)
          allow(environment).to receive(:rollout_status).and_return(kube_deployment_rollout_status)
        end

        it 'exposes rollout_status' do
          expect(subject).to include(:rollout_status)
        end
      end
    end

    context 'when deploy_boards are not available' do
      before do
        allow(environment).to receive(:has_terminals?).and_return(true)
      end

      it 'does not expose rollout_status' do
        expect(subject).not_to include(:rollout_status)
      end
    end

    context 'when pod_logs are available' do
      before do
        stub_licensed_features(pod_logs: true)
      end

      it 'exposes logs keys' do
        expect(subject).to include(:logs_path)
        expect(subject).to include(:logs_api_path)
        expect(subject).to include(:enable_advanced_logs_querying)
      end

      it 'uses k8s api when ES is not available' do
        expect(subject[:logs_api_path]).to eq(k8s_project_logs_path(environment.project, environment_name: environment.name, format: :json))
      end

      it 'uses ES api when ES is available' do
        allow(environment).to receive(:elastic_stack_available?).and_return(true)

        expect(subject[:logs_api_path]).to eq(elasticsearch_project_logs_path(environment.project, environment_name: environment.name, format: :json))
      end
    end

    context 'when pod_logs are not available' do
      before do
        stub_licensed_features(pod_logs: false)
      end

      it 'does not expose logs keys' do
        expect(subject).not_to include(:logs_path)
        expect(subject).not_to include(:logs_api_path)
        expect(subject).not_to include(:enable_advanced_logs_querying)
      end
    end
  end
end
