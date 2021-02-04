# frozen_string_literal: true

class Client < ApplicationRecord
  belongs_to :group

  validates :namespace, presence: true
  validates :name, presence: true, length: { maximum: 255 }, uniqueness: { scope: :namespace_id }
  validate :validate_email_format, unless: self.email.blank?

  # Scopes
  scope :active, -> { where(active: true) }

  def validate_email_format
    self.errors.add(:email, I18n.t(:invalid, scope: 'valid_email.validations.email')) unless ValidateEmail.valid?(self.email)
  end
end
