# frozen_string_literal: true

require 'spec_helper'

describe Environment do
  let(:project) { create(:project, :stubbed_repository) }
  let(:environment) { create(:environment, project: project) }

  describe '#pod_names' do
    context 'when environment does not have a rollout status' do
      it 'returns an empty array' do
        expect(environment.pod_names).to eq([])
      end
    end

    context 'when environment has a rollout status' do
      it 'returns the pod_names' do
        pod_name = "pod_1"
        create(:cluster, :provided_by_gcp, environment_scope: '*', projects: [project])
        create(:deployment, :success, environment: environment)

        allow_any_instance_of(Gitlab::Kubernetes::RolloutStatus).to receive(:instances)
          .and_return([{ pod_name: pod_name }])

        expect(environment.pod_names).to eq([pod_name])
      end
    end
  end

  describe '#protected?' do
    subject { environment.protected? }

    before do
      stub_licensed_features(protected_environments: feature_available)
    end

    context 'when Protected Environments feature is not available on the project' do
      let(:feature_available) { false }

      it { is_expected.to be_falsy }
    end

    context 'when Protected Environments feature is available on the project' do
      let(:feature_available) { true }

      context 'when the environment is protected' do
        before do
          create(:protected_environment, name: environment.name, project: project)
        end

        it { is_expected.to be_truthy }
      end

      context 'when the environment is not protected' do
        it { is_expected.to be_falsy }
      end
    end
  end

  describe '#protected_deployable_by_user?' do
    let(:user) { create(:user) }
    let(:protected_environment) { create(:protected_environment, :maintainers_can_deploy, name: environment.name, project: project) }

    subject { environment.protected_deployable_by_user?(user) }

    before do
      stub_licensed_features(protected_environments: true)
    end

    context 'when Protected Environments feature is not available on the project' do
      let(:feature_available) { false }

      it { is_expected.to be_truthy }
    end

    context 'when Protected Environments feature is available on the project' do
      let(:feature_available) { true }

      context 'when the environment is not protected' do
        it { is_expected.to be_truthy }
      end

      context 'when environment is protected and user dont have access to it' do
        before do
          protected_environment
        end

        it { is_expected.to be_falsy }
      end

      context 'when environment is protected and user have access to it' do
        before do
          protected_environment.deploy_access_levels.create(user: user)
        end

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#rollout_status' do
    shared_examples 'same behavior between KubernetesService and Platform::Kubernetes' do
      subject { environment.rollout_status }

      context 'when the environment has rollout status' do
        before do
          allow(environment).to receive(:has_terminals?).and_return(true)
        end

        it 'returns the rollout status from the deployment service' do
          expect(environment.deployment_platform)
            .to receive(:rollout_status).with(environment)
            .and_return(:fake_rollout_status)

          is_expected.to eq(:fake_rollout_status)
        end
      end

      context 'when the environment does not have rollout status' do
        before do
          allow(environment).to receive(:has_terminals?).and_return(false)
        end

        it { is_expected.to eq(nil) }
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
  end
end
