# frozen_string_literal: true

RSpec.shared_examples 'invalid protected environment group' do
  let(:group) { create(:group, :private) }

  it 'does not create deploy access level' do
    expect { subject }.not_to change(ProtectedEnvironment::DeployAccessLevel, :count)
  end
end

RSpec.shared_examples 'valid protected environment group' do
  let(:project_group_link) { create(:project_group_link) }
  let(:group) { project_group_link.group }
  let(:project) { project_group_link.project }

  it 'creates deploy access level' do
    expect { subject }.to change(ProtectedEnvironment::DeployAccessLevel, :count).by(1)
  end
end
