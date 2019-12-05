# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokens::PolicyWorker, type: :worker do
  describe '#perform' do
    let(:limit) { 7 }
    let!(:pat) { create(:personal_access_token, expires_at: expire_at) }

    before do
      stub_application_setting(max_personal_access_token_lifetime: limit)
    end

    context "when a token doesn't have an expiration time" do
      let(:expire_at) { nil }

      it 'enforces the policy on tokens' do
        expect { subject.perform }.to change { pat.reload.revoked }.from(false).to(true)
      end
    end

    context 'when a token expires after the given time' do
      let(:expire_at) { 8.days.from_now.to_date }

      it 'enforces the policy on tokens' do
        expect { subject.perform }.to change { pat.reload.revoked }.from(false).to(true)
      end
    end

    context 'when a token is valid' do
      let(:expire_at) { 5.days.from_now.to_date }

      it "doesn't revoked valid tokens" do
        expect { subject.perform }.not_to change { pat.reload.revoked }
      end
    end

    context 'when limit is nil' do
      let(:limit) { nil }
      let(:expire_at) { 1.day.from_now }

      it "doesn't revoked valid tokens" do
        expect { subject.perform }.not_to change { pat.reload.revoked }
      end

      it "doesn't call the revoke invalid service" do
        expect(PersonalAccessTokens::RevokeInvalidTokens).not_to receive(:new)

        subject.perform
      end
    end
  end
end
