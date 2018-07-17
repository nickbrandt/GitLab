require 'spec_helper'

describe ProtectedEnvironment do
  subject { build_stubbed(:protected_environment) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:deploy_access_levels) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:deploy_access_levels) }
  end

  describe '.protected?' do
    let(:project) { create(:project, :repository) }
    let(:different_project) { create(:project, :repository) }

    it 'returns true when the environment matches a protected environment via direct match' do
      create(:protected_environment, project: project, name: 'staging')

      expect(described_class.protected?(project, 'staging')).to be_truthy
    end

    it 'returns false when the environment matches a protected environment via direct match for a different project' do
      create(:protected_environment, project: different_project, name: 'staging')

      expect(described_class.protected?(project, 'staging')).to be_falsy
    end

    it 'returns false when the environment does not match a protected environment via direct match' do
      expect(described_class.protected?(project, 'staging')).to be_falsy
    end

    it 'returns false when the environment matches a protected environment via wildcard match' do
      create(:protected_environment, project: project, name: 'production')

      expect(described_class.protected?(project, 'production/some-environment')).to be_falsy
    end
  end

  describe '#accessible_to' do
    let(:project) { create(:project) }
    let(:environment) { create(:environment, project: project) }
    let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }
    let(:user) { create(:user) }

    subject { protected_environment.accessible_to?(user) }

    context 'when user is admin' do
      let(:user) { create(:user, :admin) }

      it { is_expected.to be_truthy }
    end

    context 'when specific access has been granted to a user' do
      before do
        create(:protected_environment_deploy_access_level, protected_environment: protected_environment, user: user)
      end

      it { is_expected.to be_truthy }
    end

    context 'when specific access has been assigned to a group and the user is member of that group' do
      let(:group) { create(:group) }

      before do
        create(:protected_environment_deploy_access_level, protected_environment: protected_environment, group: group)

        group.add_developer(user)
      end

      it { is_expected.to be_truthy }
    end

    context 'when user is project member above the permitted access level' do
      before do
        create(:protected_environment_deploy_access_level, protected_environment: protected_environment)

        project.add_maintainer(user)
      end

      it { is_expected.to be_truthy }
    end

    context 'when no permissions have been given to a user' do
      before do
        create(:protected_environment_deploy_access_level, protected_environment: protected_environment)
      end

      it { is_expected.to be_falsy }
    end

    context 'when user is a project member below the permitted access level' do
      before do
        create(:protected_environment_deploy_access_level, protected_environment: protected_environment)

        project.add_reporter(user)
      end

      it { is_expected.to be_falsy }
    end
  end
end
