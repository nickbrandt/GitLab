# frozen_string_literal: true

module Gitlab
  module CryptoHelper
    extend self

    AES256_GCM_OPTIONS = {
      algorithm: 'aes-256-gcm',
      key: Settings.attr_encrypted_db_key_base_32
    }.freeze

    AES256_GCM_IV_STATIC = Settings.attr_encrypted_db_key_base_12

    def sha256(value)
      salt = Settings.attr_encrypted_db_key_base_truncated
      ::Digest::SHA256.base64digest("#{value}#{salt}")
    end

    def aes256_gcm_encrypt(value, nonce: nil)
      return aes256_gcm_encrypt_for_non_read_db(value) if read_only?

      found_nonce = nonce || find_nonce_by_token(value)
      iv = found_nonce || create_nonce

      encrypted_token = create_encrypted_token(value, iv)
      save_token_with_nonce!(encrypted_token, value, iv) unless found_nonce
      encrypted_token
    end

    def aes256_gcm_decrypt(value)
      return unless value

      nonce = find_nonce_by_hashed_token(value)
      encrypted_token = Base64.decode64(value)
      decrypted_token = Encryptor.decrypt(AES256_GCM_OPTIONS.merge(value: encrypted_token, iv: nonce || AES256_GCM_IV_STATIC))
      aes256_gcm_encrypt(value) unless nonce
      decrypted_token
    end

    def read_only?
      Gitlab::Database.read_only?
    end

    def aes256_gcm_encrypt_for_non_read_db(value)
      create_encrypted_token(value, AES256_GCM_IV_STATIC)
    end

    def create_encrypted_token(value, iv)
      encrypted_token = Encryptor.encrypt(AES256_GCM_OPTIONS.merge(value: value, iv: iv))
      Base64.strict_encode64(encrypted_token)
    end

    def save_token_with_nonce!(encrypted_token, plaintext_token, nonce)
      return unless TokenWithIv.table_exists?

      TokenWithIv.create!(hashed_token: Digest::SHA256.digest(encrypted_token), hashed_plaintext_token: Digest::SHA256.digest(plaintext_token), iv: nonce)
    end

    def create_nonce
      cipher = OpenSSL::Cipher.new('aes-256-gcm')
      cipher.encrypt # Required before '#random_iv' can be called
      cipher.random_iv # Ensures that the IV is the correct length respective to the algorithm used.
    end

    def find_nonce_by_hashed_token(value)
      return unless TokenWithIv.table_exists?

      token_record = TokenWithIv.find_by_hashed_token(value)
      token_record&.iv
    end

    def find_nonce_by_token(value)
      return unless TokenWithIv.table_exists?

      token_record = TokenWithIv.find_by_plaintext_token(value)
      token_record&.iv
    end
  end
end
