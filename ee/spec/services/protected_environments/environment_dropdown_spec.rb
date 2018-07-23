require 'rails_helper'

describe ProtectedEnvironments::EnvironmentDropdown do
  let(:project) { create(:project) }

  let(:roles) do
    [
      { id: 40, text: 'Maintainers', before_divider: true },
      { id: 30, text: 'Developers + Maintainers', before_divider: true }
    ]
  end

  subject { described_class.new(project) }

  before do
    create(:environment, name: 'production', project: project)
    create(:environment, name: 'staging', project: project)
    create(:protected_environment, project: project)
  end

  describe '#protectable_env_names' do
    it { expect(subject.protectable_env_names).to include('staging') }
    it { expect(subject.protectable_env_names).not_to include('production') }
  end

  describe '#env_hash' do
    it 'returns a hash with text, id and title keys' do
      expect(subject.env_hash).to include(text: 'staging', id: 'staging', title: 'staging')
    end
  end

  describe '#roles' do
    it 'returns a hash with access levels for allowed to deploy option' do
      roles.each { |role| expect(subject.roles).to include(role) }
    end
  end

  describe '#roles_hash' do
    it { expect(subject.roles_hash).to include(roles: roles) }
  end
end
