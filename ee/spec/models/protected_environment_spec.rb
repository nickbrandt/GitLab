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

    context 'when user is a project member below the permitted access level' do
      before do
        create(:protected_environment_deploy_access_level, protected_environment: protected_environment)

        project.add_reporter(user)
      end

      it { is_expected.to be_falsy }
    end

    context 'when no permissions have been given to a user' do
      before do
        create(:protected_environment_deploy_access_level, protected_environment: protected_environment)
      end

      it { is_expected.to be_falsy }
    end

    context 'when only specific access has been granted to another user' do
      let(:another_user) { create(:user) }

      before do
        create(:protected_environment_deploy_access_level, protected_environment: protected_environment, user: another_user)
      end

      it 'should reject access for developers' do
        project.add_developer(user)

        expect(subject).to be_falsy
      end

      it 'should reject access for maintainers' do
        project.add_maintainer(user)

        expect(subject).to be_falsy
      end
    end

    context 'when specific access has been granted to users and roles' do
      before do
        create(:protected_environment_deploy_access_level, protected_environment: protected_environment)
      end

      it 'should allow access fow developers' do
        project.add_developer(user)

        expect(subject).to be_truthy
      end

      it 'should allow access for maintainers' do
        project.add_maintainer(user)

        expect(subject).to be_truthy
      end
    end
  end
end
