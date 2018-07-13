require 'spec_helper'

describe ProtectedEnvironmentPolicy do
  let(:current_user) { create(:user) }
  let(:project) { create(:project) }
  let(:protected_environment) { create(:protected_environment, project: project) }

  subject { described_class.new(current_user, protected_environment) }

  describe 'maintainer access' do
    before do
      project.add_maintainer(current_user)
    end

    it { is_expected.to be_allowed(:create_protected_environment) }
    it { is_expected.to be_allowed(:update_protected_environment) }
    it { is_expected.to be_allowed(:destroy_protected_environment) }
  end

  describe 'developer access' do
    before do
      project.add_developer(current_user)
    end

    it { is_expected.to be_disallowed(:create_protected_environment) }
    it { is_expected.to be_disallowed(:update_protected_environment) }
    it { is_expected.to be_disallowed(:destroy_protected_environment) }
  end
end
