# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceAccessTokens::CreateService do
  describe '#execute' do
    subject { service.execute }

    let(:admin) { create(:user, :admin) }
    let(:project) { create(:project) }

    let_it_be(:user) { create(:user, :project_bot) }
    let_it_be(:project_access_token) { create(:personal_access_token, user: user) }
    let(:params) { { name: 'token', scopes: [:api], expires_at: Date.today + 1.month } }

    let(:service) { described_class.new(admin, project, params: params) }

    context 'project access tokens' do
      let(:user) { create(:user) }

      it 'creates audit logs' do
        expect(::AuditEventService)
          .to receive(:new)
          .with(admin, user, action: :custom, custom_message: /Created personal access token with id \d+/)
          .and_call_original

        subject
      end
    end
  end
end
