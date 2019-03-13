# frozen_string_literal: true

class JiraConnectInstallation < ApplicationRecord
  attr_encrypted :shared_secret,
                 mode:      :per_attribute_iv,
                 algorithm: 'aes-256-gcm',
                 key:       Settings.attr_encrypted_db_key_base_32

  validates :client_key, :shared_secret, presence: true
  validates :base_url, presence: true, public_url: true
end
