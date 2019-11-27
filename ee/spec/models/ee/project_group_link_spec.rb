# frozen_string_literal: true

require 'spec_helper'

describe ProjectGroupLink do
  describe '#destroy' do
    let(:project) { create(:project) }
    let(:group) { create(:group) }
    let(:user) { create(:user) }
    let!(:project_group_link) { create(:project_group_link, project: project, group: group) }

    before do
      project.add_developer(user)
    end

    it 'removes related protected environment deploy access levels' do
      params = attributes_for(:protected_environment,
                              deploy_access_levels_attributes: [{ group_id: group.id }, { user_id: user.id }])

      protected_environment = ProtectedEnvironments::CreateService.new(project, user, params).execute

      expect { project_group_link.destroy! }.to change(ProtectedEnvironment::DeployAccessLevel, :count).by(-1)

      expect(protected_environment.deploy_access_levels.find_by_group_id(group)).to be_nil
      expect(protected_environment.deploy_access_levels.find_by_user_id(user)).to be_persisted
    end
  end
end
