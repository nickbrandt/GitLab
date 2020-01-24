# frozen_string_literal: true

require 'spec_helper'

describe ::EE::Gitlab::Scim::ProvisioningService do
  describe '#execute' do
    let(:group) { create(:group) }
    let(:service) { described_class.new(group, service_params) }

    before do
      stub_licensed_features(group_saml: true)
      create(:saml_provider, group: group)
    end

    context 'valid params' do
      let(:service_params) do
        {
          email: 'work@example.com',
          name: 'Test Name',
          extern_uid: 'test_uid',
          username: 'username'
        }.freeze
      end

      it 'succeeds' do
        expect(service.execute.status).to eq(:success)
      end

      it 'creates the identity' do
        expect { service.execute }.to change { Identity.count }.by(1)
      end

      it 'creates the user' do
        expect { service.execute }.to change { User.count }.by(1)
      end

      it 'creates the group member' do
        expect { service.execute }.to change { GroupMember.count }.by(1)
      end

      it 'creates the correct user attributes' do
        service.execute

        expect(User.find_by(service_params.except(:extern_uid))).to be_a(User)
      end

      it 'user record requires confirmation' do
        service.execute

        user = User.find_by(email: service_params[:email])

        expect(user).to be_present
        expect(user).not_to be_confirmed
      end

      context 'when the current minimum password length is different from the default minimum password length' do
        before do
          stub_application_setting minimum_password_length: 21
        end

        it 'creates the user' do
          expect { service.execute }.to change { User.count }.by(1)
        end
      end

      context 'existing user' do
        before do
          create(:user, email: 'work@example.com')
        end

        it 'does not create a new user' do
          expect { service.execute }.not_to change { User.count }
        end

        it 'fails with conflict' do
          expect(service.execute.status).to eq(:conflict)
        end
      end
    end

    context 'invalid params' do
      let(:service_params) do
        {
          email: 'work@example.com',
          name: 'Test Name',
          extern_uid: 'test_uid'
        }.freeze
      end

      it 'fails with error' do
        expect(service.execute.status).to eq(:error)
      end
    end
  end
end
