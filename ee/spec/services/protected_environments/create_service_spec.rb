require 'spec_helper'

describe ProtectedEnvironments::CreateService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:maintainer_access) { Gitlab::Access::MAINTAINER }

  let(:params) do
    attributes_for(:protected_environment,
                   deploy_access_levels_attributes: [{ access_level: maintainer_access }])
  end

  describe '#execute' do
    subject { described_class.new(project, user, params).execute }

    it 'should create a record on ProtectedEnvironment' do
      expect { subject }.to change(ProtectedEnvironment, :count).by(1)
    end

    it 'should create a record on ProtectedEnvironment record' do
      expect { subject }.to change(ProtectedEnvironment::DeployAccessLevel, :count).by(1)
    end
  end
end
