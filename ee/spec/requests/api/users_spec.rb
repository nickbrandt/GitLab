# frozen_string_literal: true

require 'spec_helper'

describe API::Users do
  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }

  context 'extended audit events' do
    describe "PUT /users/:id" do
      it "creates audit event when updating user with new password" do
        stub_licensed_features(extended_audit_events: true)

        put api("/users/#{user.id}", admin), params: { password: '12345678' }

        expect(AuditEvent.count).to eq(1)
      end
    end
  end

  context 'shared_runners_minutes_limit' do
    describe "PUT /users/:id" do
      context 'when user is an admin' do
        it "updates shared_runners_minutes_limit" do
          expect do
            put api("/users/#{user.id}", admin), params: { shared_runners_minutes_limit: 133 }
          end.to change { user.reload.shared_runners_minutes_limit }
                   .from(nil).to(133)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['shared_runners_minutes_limit']).to eq(133)
        end
      end

      context 'when user is not an admin' do
        it "cannot update their own shared_runners_minutes_limit" do
          expect do
            put api("/users/#{user.id}", user), params: { shared_runners_minutes_limit: 133 }
          end.not_to change { user.reload.shared_runners_minutes_limit }

          expect(response).to have_gitlab_http_status(403)
        end
      end
    end
  end
end
