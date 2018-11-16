# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Geo::Oauth::LogoutState do
  let(:salt) { '100d8cbd1750a2bb' }
  let(:return_to) { 'http://fake-secondary.com:3000/project/test' }
  let(:access_token) { '48622af3df5b5b3e09b9754f2a3e5f3f10a94b4147d155b1029d827c112524d1' }
  let(:encrypted_token) { 'fDyMq6IrHGhToG5NHiXnQ4O8AsHmSDqDTqbLP64MK0L9j0rkPEnrNDBSoWU-QS2l7sIt_Q4UMItxFhFH6xMh68uspgydVysRG9fmr_PXIU4=' }

  before do
    allow(Settings).to receive(:attr_encrypted_db_key_base)
      .and_return('4587f5984bf8f807ee320ed7b783e0c56b644a18fdcf5bc79bb2b5b38edbbb1a7037e8d79cbc880cc593880cd3ce87906ebb38466428dfd0dc70a626bb28b7ba')
  end

  describe '#encode' do
    it 'returns nil when token is nil' do
      subject = described_class.new(token: nil, return_to: return_to)

      expect(subject.encode).to be_nil
    end

    it 'returns nil when encryption fails' do
      allow_any_instance_of(OpenSSL::Cipher::AES)
        .to receive(:final) { raise OpenSSL::OpenSSLError }

      subject = described_class.new(token: access_token, return_to: return_to)

      expect(subject.encode).to be_nil
    end

    it 'returns a string with salt, encrypted access token, and return_to full path colon separated' do
      subject = described_class.new(salt: salt, token: access_token, return_to: return_to)

      expect(subject.encode).to eq("#{salt}:#{encrypted_token}:/project/test")
    end

    it 'includes a empty value for return_to into state when return_to is nil' do
      subject = described_class.new(token: access_token, return_to: nil)

      state = subject.encode

      expect(state.split(':', 3)[2]).to eq ''
    end
  end

  describe '#decode' do
    it 'returns nil when salt is nil' do
      subject = described_class.new(salt: nil, token: encrypted_token, return_to: return_to)

      expect(subject.decode).to be_nil
    end

    it 'returns nil when encrypted token is nil' do
      subject = described_class.new(salt: salt, token: nil, return_to: return_to)

      expect(subject.decode).to be_nil
    end

    it 'returns nil when decryption fails' do
      allow_any_instance_of(OpenSSL::Cipher::AES)
        .to receive(:final) { raise OpenSSL::OpenSSLError }

      subject = described_class.new(salt: salt, token: encrypted_token, return_to: return_to)

      expect(subject.decode).to be_nil
    end

    it 'returns access_token when token is recoverable' do
      subject = described_class.new(salt: salt, token: encrypted_token, return_to: return_to)

      expect(subject.decode).to eq(access_token)
    end
  end

  describe '#return_to' do
    it 'returns nil when return_to is nil' do
      subject = described_class.new(salt: salt, token: access_token, return_to: nil)

      expect(subject.return_to).to be_nil
    end

    it 'returns an emtpy string when return_to is empty' do
      subject = described_class.new(salt: salt, token: access_token, return_to: '')

      expect(subject.return_to).to eq('')
    end

    it 'returns the full path of the return_to URL' do
      subject = described_class.new(salt: salt, token: access_token, return_to: return_to)

      expect(subject.return_to).to eq('/project/test')
    end
  end
end
