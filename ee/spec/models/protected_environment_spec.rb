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
end
