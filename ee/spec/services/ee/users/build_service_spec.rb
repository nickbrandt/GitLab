# frozen_string_literal: true

require 'spec_helper'

describe Users::BuildService do
  describe '#execute' do
    let(:params) do
      { name: 'John Doe', username: 'jduser', email: 'jd@example.com', password: 'mydummypass' }
    end

    context 'with an admin user' do
      let!(:admin_user) { create(:admin) }
      let(:service) { described_class.new(admin_user, ActionController::Parameters.new(params).permit!) }

      context 'allowed params' do
        context 'with identity' do
          let(:provider) { create(:saml_provider) }
          let(:identity_params) { { extern_uid: 'uid', provider: 'group_saml', saml_provider_id: provider.id } }

          before do
            params.merge!(identity_params)
          end

          it 'sets all allowed attributes' do
            expect(Identity).to receive(:new).with(hash_including(identity_params)).and_call_original

            service.execute
          end
        end
      end
    end
  end
end
