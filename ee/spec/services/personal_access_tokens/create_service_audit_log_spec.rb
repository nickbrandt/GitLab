# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokens::CreateService do
  describe '#execute' do
    subject { service.execute }

    let(:params) { { name: 'Test token', impersonation: true, scopes: [:api], expires_at: Date.today + 1.month } }
    let(:service) { described_class.new(current_user: user, target_user: user, params: params) }

    context 'personal access tokens' do
      let(:user) { create(:user) }

      it 'creates audit logs' do
        expect(::AuditEventService)
          .to receive(:new)
          .with(user, user, action: :custom, custom_message: /Created personal access token with id \d+/, ip_address: nil)
          .and_call_original

        subject
      end

      context 'failure' do
        let(:other_user) { create(:user) }

        it 'creates propersona;lject access token audit logs' do
          expect(::AuditEventService)
            .to receive(:new)
            .with(user, other_user, action: :custom, custom_message: 'Attempted to create personal access token but failed with message: Not permitted to create', ip_address: nil)
            .and_call_original

          PersonalAccessTokens::CreateService.new(current_user: user, target_user: other_user, params: params).execute
        end
      end
    end


    end
  end
end
