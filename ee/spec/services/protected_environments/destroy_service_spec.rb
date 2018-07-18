require 'spec_helper'

describe ProtectedEnvironments::DestroyService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let!(:protected_environment) { create(:protected_environment, project: project) }
  let(:deploy_access_level) { protected_environment.deploy_access_levels.first }

  describe '#execute' do
    subject { described_class.new(project, user).execute(protected_environment) }

    it 'should delete the requested ProtectedEnvironment' do
      expect do
        subject
      end.to change { ProtectedEnvironment.count }.from(1).to(0)
    end

    it 'should delete the related DeployAccessLevel' do
      expect do
        subject
      end.to change { ProtectedEnvironment::DeployAccessLevel.count }.from(1).to(0)
    end
  end
end
