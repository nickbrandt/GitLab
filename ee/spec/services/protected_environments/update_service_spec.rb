require 'spec_helper'

describe ProtectedEnvironments::UpdateService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:maintainer_access) { Gitlab::Access::MAINTAINER }
  let(:developer_access) { Gitlab::Access::DEVELOPER }
  let(:protected_environment) { create(:protected_environment, project: project) }
  let(:deploy_access_level) { protected_environment.deploy_access_levels.first }

  let(:params) do
    {
      deploy_access_levels_attributes: [
        { id: deploy_access_level.id, access_level: developer_access },
        { access_level: maintainer_access }
      ]
    }
  end

  describe '#execute' do
    subject { described_class.new(project, user, params).execute(protected_environment) }

    before do
      project.add_maintainer(user)
    end

    it 'should update the requested ProtectedEnvironment' do
      subject

      expect(protected_environment.deploy_access_levels.count).to eq(2)
    end
  end
end
