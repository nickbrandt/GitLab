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

  describe '#protected_deployable_by_user?' do
    let(:environment) { create(:environment, project: project, name: 'production') }
    let(:user) { create(:user) }

    subject { environment.protected_deployable_by_user?(user) }

    context 'when the environment is protected' do
      before do
        create(:protected_environment, project: project, name: 'production')
      end

      context 'when no permissions have been given to this user' do
        it { is_expected.to be_falsey }
      end

      context 'when the user is an admin' do
        let(:user) { create(:user, :admin) }

        it { is_expected.to be_truthy }
      end
    end

    context 'when the user has been explicitly allowed to deploy this environment' do
      before do
        create(:protected_environment, project: project, name: 'production', authorize_user_to_deploy: user)
      end

      it { is_expected.to be_truthy }
    end

    context 'when only some other different user has been explicitly allowed to deploy this environment' do
      let(:different_user) { create(:user) }

      before do
        create(:protected_environment, project: project, name: 'production', authorize_user_to_deploy: different_user)
      end

      it { is_expected.to be_falsey }
    end

    context 'when user is in group that is allowed to deploy' do
      let(:group) { create(:group) }

      before do
        create(:group_member, user: user, group: group)
        create(:protected_environment, project: project, name: 'production', authorize_group_to_deploy: group)
      end

      it { is_expected.to be_truthy }
    end

    context 'when user is not in the group that is allowed to deploy' do
      let(:group) { create(:group) }

      before do
        create(:group_member, user: create(:user), group: group)
        create(:protected_environment, project: project, name: 'production', authorize_group_to_deploy: group)
      end

      it { is_expected.to be_falsey }
    end

    context 'when user is project member below the permitted access level' do
      before do
        create(:project_member, :developer, user: user)
        create(:protected_environment, :masters_can_deploy, project: project, name: 'production')
      end

      it { is_expected.to be_falsey }
    end

    context 'when user is project member above the permitted access level' do
      before do
        create(:project_member, :master, project: project, user: user)
        create(:protected_environment, :masters_can_deploy, project: project, name: 'production')
      end

      it { is_expected.to be_truthy }
    end
  end
end
