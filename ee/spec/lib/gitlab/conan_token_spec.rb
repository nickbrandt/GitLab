# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::ConanToken do
  let(:base_secret) { SecureRandom.base64(64) }

  let(:jwt_secret) do
    OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest::SHA256.new,
      base_secret,
      described_class::HMAC_KEY
    )
  end

  before do
    allow(Settings).to receive(:attr_encrypted_db_key_base).and_return(base_secret)
  end

  def build_jwt(personal_access_token_id:, user_id:)
    JSONWebToken::HMACToken.new(jwt_secret).tap do |jwt|
      jwt['pat'] = personal_access_token_id
      jwt['u'] = user_id || user_id
      jwt.expire_time = jwt.issued_at + 1.hour
    end
  end

  describe '.from_personal_access_token' do
    it 'sets personal access token id and user id' do
      personal_access_token = double(id: 123, user_id: 456)

      token = described_class.from_personal_access_token(personal_access_token)

      expect(token.personal_access_token_id).to eq(123)
      expect(token.user_id).to eq(456)
    end
  end

  describe '.decode' do
    it 'sets personal access token id and user id' do
      jwt = build_jwt(personal_access_token_id: 123, user_id: 456)

      token = described_class.decode(jwt.encoded)

      expect(token.personal_access_token_id).to eq(123)
      expect(token.user_id).to eq(456)
    end
  end

  describe '#to_s' do
    it 'returns the encoded JWT' do
      allow(SecureRandom).to receive(:uuid).and_return('u-u-i-d')

      Timecop.freeze do
        jwt = build_jwt(personal_access_token_id: 123, user_id: 456)

        token = described_class.new(personal_access_token_id: 123, user_id: 456)

        expect(token.to_s).to eq(jwt.encoded)
      end
    end
  end
end
