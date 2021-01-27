# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CryptoHelper do
  describe '.sha256' do
    it 'generates SHA256 digest Base46 encoded' do
      digest = described_class.sha256('some-value')

      expect(digest).to match %r{\A[A-Za-z0-9+/=]+\z}
      expect(digest).to eq digest.strip
    end
  end

  describe '.aes256_gcm_encrypt' do
    it 'is Base64 encoded string without new line character' do
      encrypted = described_class.aes256_gcm_encrypt('some-value')

      expect(encrypted).to match %r{\A[A-Za-z0-9+/=]+\z}
      expect(encrypted).not_to include "\n"
    end

    it 'saves hashed token with iv value in database' do
      expect { described_class.aes256_gcm_encrypt('some-value') }.to change { TokenWithIv.count }.by(1)
    end

    it 'saves hashed token in database' do
      encrypted_token = described_class.aes256_gcm_encrypt('some-value')

      expect(TokenWithIv.last.hashed_token).to eq(Digest::SHA256.digest(encrypted_token))
    end

    it 'saves digested plaintext token in database' do
      described_class.aes256_gcm_encrypt('some-value')

      expect(TokenWithIv.last.hashed_plaintext_token).to eq(Digest::SHA256.digest('some-value'))
    end

    context 'when we are encrypting the same token for a second time' do
      before do
        described_class.aes256_gcm_encrypt('some-value')
      end

      it 'does not save digested plaintext token in database' do
        expect { described_class.aes256_gcm_encrypt('some-value') }.not_to change { TokenWithIv.count }
      end
    end

    context 'when read only is true' do
      before do
        allow(described_class).to receive(:read_only?).and_return(true)
      end

      it 'does not save tokens in database' do
        expect { described_class.aes256_gcm_encrypt('some-value') }.not_to change { TokenWithIv.count }
      end

      it 'encrypts using static iv' do
        expect(Encryptor).to receive(:encrypt).with(described_class::AES256_GCM_OPTIONS.merge(value: 'some-value', iv: described_class::AES256_GCM_IV_STATIC)).and_return('hashed_value')

        described_class.aes256_gcm_encrypt('some-value')
      end
    end
  end

  describe '.aes256_gcm_decrypt' do
    context 'when token was encrypted using static nonce' do
      let(:encrypted) { described_class.aes256_gcm_encrypt('some-value', nonce: described_class::AES256_GCM_IV_STATIC) }

      it 'correctly decrypts encrypted string' do
        decrypted = described_class.aes256_gcm_decrypt(encrypted)

        expect(decrypted).to eq 'some-value'
      end

      it 'decrypts a value when it ends with a new line character' do
        decrypted = described_class.aes256_gcm_decrypt(encrypted + "\n")

        expect(decrypted).to eq 'some-value'
      end

      it 'saves hashed token with iv value in database' do
        expect { described_class.aes256_gcm_decrypt(encrypted) }.to change { TokenWithIv.count }.by(1)
      end
    end

    context 'when token was encrypted using random nonce' do
      let!(:encrypted) { described_class.aes256_gcm_encrypt('some-value') }

      it 'correctly decrypts encrypted string' do
        decrypted = described_class.aes256_gcm_decrypt(encrypted)

        expect(decrypted).to eq 'some-value'
      end

      it 'does not save hashed token with iv value in database' do
        expect { described_class.aes256_gcm_decrypt(encrypted) }.not_to change { TokenWithIv.count }
      end
    end
  end
end
