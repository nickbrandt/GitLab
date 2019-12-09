# frozen_string_literal: true

require 'spec_helper'

describe PersonalAccessToken do
  describe 'scopes' do
    let_it_be(:expired_token) { create(:personal_access_token, expires_at: 1.day.ago) }
    let_it_be(:valid_token) { create(:personal_access_token, expires_at: 1.day.from_now) }
    let!(:pat) { create(:personal_access_token, expires_at: expiration_date) }

    describe 'with_expires_at_after' do
      subject { described_class.with_expires_at_after(2.days.from_now) }

      let(:expiration_date) { 3.days.from_now }

      it 'includes the tokens with higher than the lifetime expires_at value' do
        expect(subject).to contain_exactly(pat)
      end

      it "doesn't contain expired tokens" do
        expect(subject).not_to include(expired_token)
      end

      it "doesn't contain tokens within the expiration time" do
        expect(subject).not_to include(valid_token)
      end
    end

    describe 'with_no_expires_at' do
      subject { described_class.with_expires_at_after(2.days.from_now) }

      let(:expiration_date) { nil }

      it 'includes the tokens with nil expires_at' do
        expect(described_class.with_no_expires_at).to contain_exactly(pat)
      end

      it "doesn't contain expired tokens" do
        expect(subject).not_to include(expired_token)
      end

      it "doesn't contain tokens within the expiration time" do
        expect(subject).not_to include(valid_token)
      end
    end
  end

  describe 'validations' do
    let(:personal_access_token) { build(:personal_access_token) }

    it 'allows to define expires_at' do
      personal_access_token.expires_at = 1.day.from_now

      expect(personal_access_token).to be_valid
    end

    it "allows to don't define expires_at" do
      personal_access_token.expires_at = nil

      expect(personal_access_token).to be_valid
    end

    context 'with expiration policy' do
      let(:pat_expiration_policy) { 30 }
      let(:max_expiration_date) { pat_expiration_policy.days.from_now }

      before do
        stub_ee_application_setting(max_personal_access_token_lifetime: pat_expiration_policy)
      end

      context 'when the feature is licensed' do
        before do
          stub_licensed_features(personal_access_token_expiration_policy: true)
        end

        it 'requires to be less or equal than the max_personal_access_token_lifetime' do
          personal_access_token.expires_at = max_expiration_date + 1.day

          expect(personal_access_token).not_to be_valid
          expect(personal_access_token.errors[:expires_at].first).to eq('is invalid')
        end

        it "can't be blank" do
          personal_access_token.expires_at = nil

          expect(personal_access_token).not_to be_valid
          expect(personal_access_token.errors[:expires_at].first).to eq("can't be blank")
        end
      end

      context 'when the feature is not available' do
        before do
          stub_licensed_features(personal_access_token_expiration_policy: false)
        end

        it 'allows to be after the max_personal_access_token_lifetime' do
          personal_access_token.expires_at = max_expiration_date + 1.day

          expect(personal_access_token).to be_valid
        end
      end
    end
  end

  describe '.pluck_names' do
    it 'returns the names of the tokens' do
      pat1 = create(:personal_access_token)
      pat2 = create(:personal_access_token)

      expect(described_class.pluck_names).to contain_exactly(pat1.name, pat2.name)
    end
  end

  describe '.with_invalid_expires_at' do
    subject { described_class.with_invalid_expires_at(2.days.from_now) }

    it 'includes the tokens with invalid expires_at' do
      pat_with_no_expires_at = create(:personal_access_token, expires_at: nil)
      pat_with_longer_expires_at = create(:personal_access_token, expires_at: 3.days.from_now)

      expect(subject).to contain_exactly(pat_with_no_expires_at, pat_with_longer_expires_at)
    end

    it "doesn't include valid tokens" do
      valid_token = create(:personal_access_token, expires_at: 1.day.from_now)

      expect(subject).not_to include(valid_token)
    end

    it "doesn't include revoked tokens" do
      revoked_token = create(:personal_access_token, revoked: true)

      expect(subject).not_to include(revoked_token)
    end

    it "doesn't include expired tokens" do
      expired_token = create(:personal_access_token, expires_at: 1.day.ago)

      expect(subject).not_to include(expired_token)
    end
  end
end
