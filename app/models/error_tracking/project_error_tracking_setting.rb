# frozen_string_literal: true

module ErrorTracking
  class ProjectErrorTrackingSetting < ActiveRecord::Base
    belongs_to :project

    validates :api_url, length: { maximum: 255 }, public_url: true, url: { enforce_sanitization: true }

    validate :validate_api_url_path

    attr_encrypted :token,
      mode: :per_attribute_iv,
      key: Settings.attr_encrypted_db_key_base_truncated,
      algorithm: 'aes-256-gcm'

    def sentry_client
      Sentry::Client.new(api_url, token)
    end

    def sentry_external_url
      extract_external_url
    end

    private

    # http://HOST/api/0/projects/ORG/PROJECT
    # ->
    # http://HOST/ORG/PROJECT
    def extract_external_url
      api_url.sub('api/0/projects/', '')
    end

    def validate_api_url_path
      unless URI(api_url).path.starts_with?('/api/0/projects')
        errors.add(:api_url, 'path needs to start with /api/0/projects')
      end
    rescue URI::InvalidURIError
    end
  end
end
