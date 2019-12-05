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

  describe '#personal_access_token_expiration_policy_enabled?' do
    subject { helper.personal_access_token_expiration_policy_enabled? }

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
end
