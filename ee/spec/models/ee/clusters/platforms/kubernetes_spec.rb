require 'spec_helper'

describe Clusters::Platforms::Kubernetes do
  include KubernetesHelpers

  describe '#rollout_status' do
    let(:deployments) { [] }
    let(:pods) { [] }
    let(:service) { create(:cluster_platform_kubernetes, :configured) }
    let!(:cluster) { create(:cluster, :project, enabled: true, platform_kubernetes: service) }
    let(:project) { cluster.project }
    let(:environment) { build(:environment, project: project, name: "env", slug: "env-000000") }
    let(:cache_data) { Hash(deployments: deployments, pods: pods) }

    subject(:rollout_status) { service.rollout_status(environment, cache_data) }

    context 'legacy deployments based on app label' do
      let(:legacy_deployment) do
        kube_deployment(name: 'legacy-deployment').tap do |deployment|
          deployment['metadata']['annotations'].delete('app.gitlab.com/env')
          deployment['metadata']['annotations'].delete('app.gitlab.com/app')
          deployment['metadata']['labels']['app'] = environment.slug
        end
      end

      let(:legacy_pod) do
        kube_pod(name: 'legacy-pod').tap do |pod|
          pod['metadata']['annotations'].delete('app.gitlab.com/env')
          pod['metadata']['annotations'].delete('app.gitlab.com/app')
          pod['metadata']['labels']['app'] = environment.slug
        end
      end

      context 'only legacy deployments' do
        let(:deployments) { [legacy_deployment] }
        let(:pods) { [legacy_pod] }

        it 'contains nothing' do
          expect(rollout_status).to be_kind_of(::Gitlab::Kubernetes::RolloutStatus)

          expect(rollout_status.deployments).to eq([])
        end

        it 'has the has_legacy_app_label flag' do
          expect(rollout_status).to be_has_legacy_app_label
        end
      end

      context 'new deployment based on annotations' do
        let(:matched_deployment) { kube_deployment(name: 'matched-deployment', environment_slug: environment.slug, project_slug: project.full_path_slug) }
        let(:matched_pod) { kube_pod(environment_slug: environment.slug, project_slug: project.full_path_slug) }
        let(:deployments) { [matched_deployment, legacy_deployment] }
        let(:pods) { [matched_pod, legacy_pod] }

        it 'contains only matching deployments' do
          expect(rollout_status).to be_kind_of(::Gitlab::Kubernetes::RolloutStatus)

          expect(rollout_status.deployments.map(&:name)).to contain_exactly('matched-deployment')
        end

        it 'does have the has_legacy_app_label flag' do
          expect(rollout_status).to be_has_legacy_app_label
        end
      end

      context 'deployment with app label not matching the environment' do
        let(:other_deployment) do
          kube_deployment(name: 'other-deployment').tap do |deployment|
            deployment['metadata']['annotations'].delete('app.gitlab.com/env')
            deployment['metadata']['annotations'].delete('app.gitlab.com/app')
            deployment['metadata']['labels']['app'] = 'helm-app-label'
          end
        end

        let(:other_pod) do
          kube_pod(name: 'other-pod').tap do |pod|
            pod['metadata']['annotations'].delete('app.gitlab.com/env')
            pod['metadata']['annotations'].delete('app.gitlab.com/app')
            pod['metadata']['labels']['app'] = environment.slug
          end
        end

        let(:deployments) { [other_deployment] }
        let(:pods) { [other_pod] }

        it 'does not have the has_legacy_app_label flag' do
          expect(rollout_status).not_to be_has_legacy_app_label
        end
      end
    end

    context 'with valid deployments' do
      let(:matched_deployment) { kube_deployment(environment_slug: environment.slug, project_slug: project.full_path_slug) }
      let(:unmatched_deployment) { kube_deployment }
      let(:matched_pod) { kube_pod(environment_slug: environment.slug, project_slug: project.full_path_slug) }
      let(:unmatched_pod) { kube_pod(environment_slug: environment.slug, project_slug: project.full_path_slug, status: 'Pending') }
      let(:deployments) { [matched_deployment, unmatched_deployment] }
      let(:pods) { [matched_pod, unmatched_pod] }

      it 'creates a matching RolloutStatus' do
        expect(rollout_status).to be_kind_of(::Gitlab::Kubernetes::RolloutStatus)
        expect(rollout_status.deployments.map(&:annotations)).to eq([
          { 'app.gitlab.com/app' => project.full_path_slug, 'app.gitlab.com/env' => 'env-000000' }
        ])
      end
    end

    context 'with empty list of deployments' do
      it 'creates a matching RolloutStatus' do
        expect(rollout_status).to be_kind_of(::Gitlab::Kubernetes::RolloutStatus)
        expect(rollout_status).to be_not_found
      end
    end
  end

  describe '#read_pod_logs' do
    let(:cluster) { create(:cluster, :project, platform_kubernetes: service) }
    let(:service) { create(:cluster_platform_kubernetes, :configured) }
    let(:pod_name) { 'pod-1' }
    let(:namespace) { 'app' }

    subject { service.read_pod_logs(pod_name, namespace) }

    context 'when kubernetes responds with valid logs' do
      before do
        stub_kubeclient_logs(pod_name, namespace)
      end

      shared_examples 'successful log request' do
        it { expect(subject.body).to eq("\"Log 1\\nLog 2\\nLog 3\"") }
      end

      context 'on a project level cluster' do
        let(:cluster) { create(:cluster, :project, platform_kubernetes: service) }

        include_examples 'successful log request'
      end

      context 'on a group level cluster' do
        let(:cluster) { create(:cluster, :group, platform_kubernetes: service) }

        include_examples 'successful log request'
      end

      context 'on an instance level cluster' do
        let(:cluster) { create(:cluster, :instance, platform_kubernetes: service) }

        include_examples 'successful log request'
      end
    end

    context 'when kubernetes responds with 500s' do
      before do
        stub_kubeclient_logs(pod_name, namespace, status: 500)
      end

      it { expect { subject }.to raise_error(::Kubeclient::HttpError) }
    end

    context 'when kubernetes responds with 404s' do
      before do
        stub_kubeclient_logs(pod_name, namespace, status: 404)
      end

      it { is_expected.to be_empty }
    end
  end

  describe '#calculate_reactive_cache_for' do
    let(:cluster) { create(:cluster, :project, platform_kubernetes: service) }
    let(:service) { create(:cluster_platform_kubernetes, :configured) }
    let(:namespace) { 'app' }
    let(:environment) { instance_double(Environment, deployment_namespace: namespace) }

    subject { service.calculate_reactive_cache_for(environment) }

    before do
      allow(service).to receive(:read_pods).and_return([])
    end

    context 'when kubernetes responds with valid deployments' do
      before do
        stub_kubeclient_deployments(namespace)
      end

      shared_examples 'successful deployment request' do
        it { is_expected.to include(deployments: [kube_deployment]) }
      end

      context 'on a project level cluster' do
        let(:cluster) { create(:cluster, :project, platform_kubernetes: service) }

        include_examples 'successful deployment request'
      end

      context 'on a group level cluster' do
        let(:cluster) { create(:cluster, :group, platform_kubernetes: service) }

        include_examples 'successful deployment request'
      end

      context 'on an instance level cluster' do
        let(:cluster) { create(:cluster, :instance, platform_kubernetes: service) }

        include_examples 'successful deployment request'
      end
    end

    context 'when kubernetes responds with 500s' do
      before do
        stub_kubeclient_deployments(namespace, status: 500)
      end

      it { expect { subject }.to raise_error(::Kubeclient::HttpError) }
    end

    context 'when kubernetes responds with 404s' do
      before do
        stub_kubeclient_deployments(namespace, status: 404)
      end

      it { is_expected.to include(deployments: []) }
    end
  end
end
