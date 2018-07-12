require 'rails_helper'

describe ProtectedEnvironments::CreateService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:master_access) { Gitlab::Access::MASTER }

  let(:params) do
    attributes_for(:protected_environment,
                   deploy_access_levels_attributes: [{ access_level: master_access }])
  end

  describe '#execute' do
    subject { described_class.new(project, user, params).execute }

    context 'when the user is authorized' do
      before do
        project.add_master(user)
      end

      it 'should create a record on ProtectedEnvironment' do
        expect { subject }.to change(ProtectedEnvironment, :count).by(1)
      end

      it 'should create a record on ProtectedEnvironment record' do
        expect { subject }.to change(ProtectedEnvironment::DeployAccessLevel, :count).by(1)
      end
    end

    context 'when the user is not authorized' do
      before do
        project.add_developer(user)
      end

      it 'should raise a Gitlab::AccessDeniedError' do
        expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end
  end
end
