# frozen_string_literal: true

class TerraformStateUploader < GitlabUploader
  include ObjectStorage::Concern

  storage_options Gitlab.config.uploads

  delegate :project_id, to: :model

  # Use Lockbox to encrypt/decrypt the stored file (registers CarrierWave callbacks)
  encrypt(key: :key)

  def filename
    "#{model.id}.tfstate"
  end

  def store_dir
    project_id.to_s
  end

  def key
    OpenSSL::HMAC.digest('SHA256', Gitlab::Application.secrets.db_key_base, project_id.to_s)
  end
end
