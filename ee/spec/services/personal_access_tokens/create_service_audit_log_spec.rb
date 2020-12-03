# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokens::CreateService do
  describe '#execute' do
    subject { service.execute }

    let(:params) { { name: 'Test token', impersonation: true, scopes: [:api], expires_at: Date.today + 1.month } }
    let(:service) { described_class.new(current_user: user, target_user: user, params: params) }

    context 'personal access tokens' do
      let(:user) { create(:user) }

      context 'with valid params' do
        it 'creates audit logs with success message' do
          expect(::AuditEventService)
            .to receive(:new)
            .with(user, user, action: :custom, custom_message: /Created personal access token with id \d+/, ip_address: nil)
            .and_call_original

          subject
        end
      end

      context 'with invalid permission' do
        let(:other_user) { create(:user) }

        it 'creates audit logs with failure message' do
          expect(::AuditEventService)
            .to receive(:new)
            .with(user, other_user, action: :custom, custom_message: 'Attempted to create personal access token but failed with message: Not permitted to create', ip_address: nil)
            .and_call_original

          PersonalAccessTokens::CreateService.new(current_user: user, target_user: other_user, params: params).execute
        end
      end
    end

    context 'project access tokens' do
      let_it_be(:user) { create(:user, :project_bot) }

      let(:admin) { create(:user, :admin) }
      let(:project) { create(:project) }

      let_it_be(:project_access_token) { create(:personal_access_token, user: user) }
      let(:params) { { name: 'token', scopes: [:api], expires_at: Date.today + 1.month } }

      context 'with valid params' do
        let(:user) { create(:user, :project_bot) }

        it 'creates audit logs with success message' do
          expect(::AuditEventService)
            .to receive(:new)
            .with(user, user, action: :custom, custom_message: /Created project access token with id \d+/, ip_address: nil)
            .and_call_original

         subject
        end
      end
    end
  end
end
