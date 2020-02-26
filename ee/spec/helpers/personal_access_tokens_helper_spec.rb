# frozen_string_literal: true

require 'spec_helper'

describe PersonalAccessTokensHelper do
  describe '#personal_access_token_expiration_policy_licensed?' do
    subject { helper.personal_access_token_expiration_policy_licensed? }

    context 'when is not licensed' do
      before do
        stub_licensed_features(personal_access_token_expiration_policy: false)
      end

      it { is_expected.to be_falsey }
    end

    context 'when is licensed' do
      before do
        stub_licensed_features(personal_access_token_expiration_policy: true)
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#instance_level_personal_access_token_expiration_policy_enabled?' do
    subject { helper.instance_level_personal_access_token_expiration_policy_enabled? }

    context 'when is licensed and used' do
      before do
        stub_licensed_features(personal_access_token_expiration_policy: true)
        stub_application_setting(max_personal_access_token_lifetime: 1)
      end

      it { is_expected.to be_truthy }
    end

    context 'when is not licensed' do
      before do
        stub_licensed_features(personal_access_token_expiration_policy: false)
      end

      it { is_expected.to be_falsey }
    end

    context 'when is licensed but not used' do
      before do
        stub_licensed_features(personal_access_token_expiration_policy: true)
        stub_application_setting(max_personal_access_token_lifetime: nil)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#enforce_instance_level_personal_access_token_expiry_policy?' do
    subject { helper.enforce_instance_level_personal_access_token_expiry_policy? }

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
end
