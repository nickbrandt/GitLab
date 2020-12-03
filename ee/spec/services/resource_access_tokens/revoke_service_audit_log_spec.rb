# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceAccessTokens::RevokeService do
  describe '#execute' do
    subject { service.execute }

    let_it_be(:admin) { create(:user, :admin) }
    let(:service) { described_class.new(admin, resource, access_token) }

    context 'project access tokens' do
      let(:resource) { create(:project) }
      let(:project_bot_user) { create(:user, :project_bot) }
      let(:access_token) { create(:personal_access_token, user: project_bot_user) }

      context 'when successfully revoked' do
        before do
          resource.add_maintainer(admin)
          resource.add_maintainer(project_bot_user)
        end

        it 'creates audit log success message' do
          expect(::AuditEventService)
            .to receive(:new)
            .with(admin, project_bot_user, action: :custom, custom_message: "Revoked project access token with id #{access_token.id}")
            .and_call_original

          subject
        end
      end

      context 'when revocation fails' do
        before do
          resource.add_maintainer(admin)
        end

        it 'creates audit log failure message' do
          expect(::AuditEventService)
            .to receive(:new)
            .with(admin, project_bot_user, action: :custom, custom_message: "Attempted to revoke project access token with id #{access_token.id} but failed with message: Failed to find bot user")
            .and_call_original

          subject
        end
      end
    end
  end
end
