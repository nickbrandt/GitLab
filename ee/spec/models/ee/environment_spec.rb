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
        create(:deployment, environment: environment)

        allow_any_instance_of(Gitlab::Kubernetes::RolloutStatus).to receive(:instances)
          .and_return([{ pod_name: pod_name }])

        expect(environment.pod_names).to eq([pod_name])
      end
    end
  end

  describe '#protected?' do
    let(:environment) { create(:environment, project: project, name: 'production') }

    subject { environment.protected? }

    context 'when there is a matching ProtectedEnvironment for this project' do
      before do
        create(:protected_environment, project: project, name: 'production')
      end

      it { is_expected.to be_truthy }
    end

    context 'when there is no matching ProtectedEnvironment for this project' do
      it { is_expected.to be_falsey }
    end

    context 'when there is a matching ProtectedEnvironment but for a different project' do
      let(:different_project) { create(:project, :stubbed_repository) }

      before do
        create(:protected_environment, project: different_project, name: 'production')
      end

      it { is_expected.to be_falsey }
    end
  end
end
