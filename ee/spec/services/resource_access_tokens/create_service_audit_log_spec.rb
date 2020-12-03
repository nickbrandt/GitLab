# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceAccessTokens::CreateService do
  describe '#execute' do
    subject { service.execute }

    let(:admin) { create(:user, :admin) }
    let(:project) { create(:project) }
    let_it_be(:user) { create(:user, :project_bot) }
    let_it_be(:project_access_token) { create(:personal_access_token, user: user) }
    let(:params) { { name: 'Test token', impersonation: true, scopes: [:api], expires_at: Date.today + 1.month } }

    let(:service) { described_class.new(admin, project, params: params) }

    context 'project access tokens' do
      context 'when project access token is successfully created' do

        it 'creates project access token audit log success message' do
          expect(::AuditEventService)
            .to receive(:new)
            .with(admin, action: :custom, custom_message: /Attempted to create project access token but failed with message: User does not have permission to create project Access Token/, ip_address: nil)
            .and_call_original

          subject
        end
      end
    end
  end
end
