# frozen_string_literal: true

require 'spec_helper'

describe PersonalAccessTokensHelper do
  describe '#personal_access_token_expiration_policy_enabled?' do
    subject { helper.personal_access_token_expiration_policy_enabled? }

    let(:user) { build(:user) }

    before do
      allow(helper).to receive(:current_user) { user }
    end

    context 'when licensed and used' do
      before do
        allow(helper).to receive(:instance_level_personal_access_token_expiration_policy_enabled?) { true }
      end

      context 'when the user does not belong to a managed group' do
        it { is_expected.to be_truthy }
      end

      context 'when the user belongs to a managed group' do
        let(:user) { build(:user, :group_managed) }

        it { is_expected.to be_falsey }
      end
    end

    context 'when not licensed or used' do
      before do
        allow(helper).to receive(:instance_level_personal_access_token_expiration_policy_enabled?) { false }
      end

      context 'when the user does not belong to a managed group' do
        it { is_expected.to be_falsey }
      end

      context 'when the user belongs to a managed group' do
        let(:user) { build(:user, :group_managed) }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#personal_access_token_max_expiry_date' do
    subject { helper.personal_access_token_max_expiry_date }

    it 'returns the instance level personal access token expiry date' do
      expect(helper).to receive(:instance_level_personal_access_token_max_expiry_date).and_return(20.days.from_now)

      expect(subject).to be_like_time(20.days.from_now)
    end
  end

  describe '#personal_access_token_expiration_policy_licensed?' do
    subject { helper.personal_access_token_expiration_policy_licensed? }

    context 'when licensed' do
      before do
        stub_licensed_features(personal_access_token_expiration_policy: true)
      end

      it { is_expected.to be_truthy }
    end

    context 'when un-licensed' do
      before do
        stub_licensed_features(personal_access_token_expiration_policy: false)
      end

      it { is_expected.to be_falsey }
    end
  end
end
