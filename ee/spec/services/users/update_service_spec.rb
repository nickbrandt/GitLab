# frozen_string_literal: true
require 'spec_helper'

describe Users::UpdateService do
  let(:user) { create(:user) }

  describe '#execute' do
    it 'does not update email if an user has group managed account' do
      allow(user).to receive(:group_managed_account?).and_return(true)

      expect do
        update_user(user, { email: 'foreign@email' })
      end.not_to change { user.reload.email }
    end

    it 'does not update commit email if an user has group managed account' do
      allow(user).to receive(:group_managed_account?).and_return(true)

      expect do
        update_user(user, { commit_email: 'foreign@email' })
      end.not_to change { user.reload.commit_email }
    end

    it 'does not update public if an user has group managed account' do
      allow(user).to receive(:group_managed_account?).and_return(true)

      expect do
        update_user(user, { public_email: 'foreign@email' })
      end.not_to change { user.reload.public_email }
    end

    it 'does not update public if an user has group managed account' do
      allow(user).to receive(:group_managed_account?).and_return(true)

      expect do
        update_user(user, { notification_email: 'foreign@email' })
      end.not_to change { user.reload.notification_email }
    end

    context 'with an admin user' do
      let!(:admin_user) { create(:admin) }
      let(:service) { described_class.new(admin_user, ActionController::Parameters.new(params).permit!) }
      let(:params) do
        { name: 'John Doe', username: 'jduser', email: 'jd@example.com', password: 'mydummypass' }
      end

      context 'allowed params' do
        context 'with identity' do
          let(:provider) { create(:saml_provider) }
          let(:identity_params) { { extern_uid: 'uid', provider: 'group_saml', saml_group_id: provider.group.id } }

          before do
            params.merge!(identity_params)
          end

          it 'successfully adds identity to user' do
            result = update_user(user, { extern_uid: 'uid', provider: 'group_saml', saml_provider_id: provider.id })

            expect(result).to be true
            expect(user.identities.last.saml_provider_id).to eq(provider.id)
            expect(user.identities.last.extern_uid).to eq('uid')
            expect(user.identities.last.provider).to eq('group_saml')
          end
        end
      end
    end

    def update_user(user, opts)
      described_class.new(user, opts.merge(user: user)).execute!
    end
  end
end
