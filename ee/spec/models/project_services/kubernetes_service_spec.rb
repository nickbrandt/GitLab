require 'spec_helper'

describe KubernetesService, models: true, use_clean_rails_memory_store_caching: true do
  include KubernetesHelpers
  include ReactiveCachingHelpers

  shared_examples 'same behavior between KubernetesService and Platform::Kubernetes' do
    let(:service) { project.deployment_platform }

    describe '#rollout_status' do
      let(:environment) { build(:environment, project: project, name: "env", slug: "env-000000") }

      subject(:rollout_status) { service.rollout_status(environment) }

      context 'with valid deployments' do
        let(:matched_deployment) { kube_deployment(environment_slug: environment.slug, project_slug: project.full_path_slug) }
        let(:unmatched_deployment) { kube_deployment }
        let(:matched_pod) { kube_pod(environment_slug: environment.slug, project_slug: project.full_path_slug) }
        let(:unmatched_pod) { kube_pod(environment_slug: environment.slug, project_slug: project.full_path_slug, status: 'Pending') }

        before do
          stub_reactive_cache(
            service,
            deployments: [matched_deployment, unmatched_deployment],
            pods: [matched_pod, unmatched_pod]
          )
        end

        it 'creates a matching RolloutStatus' do
          expect(rollout_status).to be_kind_of(::Gitlab::Kubernetes::RolloutStatus)
          expect(rollout_status.deployments.map(&:annotations)).to eq([
            { 'app.gitlab.com/app' => project.full_path_slug, 'app.gitlab.com/env' => 'env-000000' }
          ])
        end
      end

      context 'with empty list of deployments' do
        before do
          stub_reactive_cache(
            service,
            deployments: []
          )
        end

        it 'creates a matching RolloutStatus' do
          expect(rollout_status).to be_kind_of(::Gitlab::Kubernetes::RolloutStatus)
          expect(rollout_status).to be_not_found
        end
      end

      context 'not yet loaded deployments' do
        before do
          stub_reactive_cache
        end

        it 'creates a matching RolloutStatus' do
          expect(rollout_status).to be_kind_of(::Gitlab::Kubernetes::RolloutStatus)
          expect(rollout_status).to be_loading
        end
      end
    end
  end

  context 'when user configured kubernetes from Integration > Kubernetes' do
    let(:project) { create(:kubernetes_project) }

    it_behaves_like 'same behavior between KubernetesService and Platform::Kubernetes'
  end

  context 'when user configured kubernetes from CI/CD > Clusters' do
    let!(:cluster) { create(:cluster, :project, :provided_by_gcp) }
    let(:project) { cluster.project }

    it_behaves_like 'same behavior between KubernetesService and Platform::Kubernetes'
  end

  describe '#calculate_reactive_cache' do
    let(:project) { create(:kubernetes_project) }
    let(:service) { project.deployment_platform }

    subject { service.calculate_reactive_cache }

    context 'when service is inactive' do
      before do
        service.active = false
      end

      it { is_expected.to be_nil }
    end

    context 'when kubernetes responds with valid pods and deployments' do
      before do
        stub_kubeclient_pods
        stub_kubeclient_deployments
      end

      it { is_expected.to eq(pods: [kube_pod], deployments: [kube_deployment]) }
    end

    context 'when kubernetes responds with 500s' do
      before do
        stub_kubeclient_pods(status: 500)
        stub_kubeclient_deployments(status: 500)
      end

      it { expect { subject }.to raise_error(Kubeclient::HttpError) }
    end

    context 'when kubernetes responds with 404s' do
      before do
        stub_kubeclient_pods(status: 404)
        stub_kubeclient_deployments(status: 404)
      end

      it { is_expected.to eq(pods: [], deployments: []) }
    end
  end
end
