# frozen_string_literal: true

class StatusPageSetting < ApplicationRecord
  # AWS validations. See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25863#note_295772553
  AWS_BUCKET_NAME_REGEXP = /\A[a-z0-9][a-z0-9\-.]*\z/.freeze
  AWS_ACCESS_KEY_REGEXP  = /\A[A-Z0-9]{20}\z/.freeze
  AWS_SECRET_KEY_REGEXP  = /\A[A-Za-z0-9\/+=]{40}\z/.freeze

  belongs_to :project

  attr_encrypted :aws_secret_key,
    mode:      :per_attribute_iv,
    algorithm: 'aes-256-gcm',
    key:       Settings.attr_encrypted_db_key_base_32

  before_validation :check_secret_changes

  validates :aws_s3_bucket_name,
            length: { minimum: 3, maximum: 63 },
            presence: true,
            format: { with: AWS_BUCKET_NAME_REGEXP }
  validates :aws_access_key,
            presence: true,
            format: { with: AWS_ACCESS_KEY_REGEXP }
  validates :aws_secret_key,
            presence: true,
            format: { with: AWS_SECRET_KEY_REGEXP }
  validates :project, :aws_region, :encrypted_aws_secret_key,
            presence: true
  validates :enabled, inclusion: { in: [true, false] }

  scope :enabled, -> { where(enabled: true) }

  def masked_aws_secret_key
    '*' * 40
  end

  private

  def check_secret_changes
    return unless masked_aws_secret_key == aws_secret_key

    restore_attributes [:aws_secret_key, :encrypted_aws_secret_key, :encrypted_aws_secret_key_iv]
  end
end
