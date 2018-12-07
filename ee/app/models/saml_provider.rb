# frozen_string_literal: true

class SamlProvider < ActiveRecord::Base
  belongs_to :group
  has_many :identities

  validates :group, presence: true, top_level_group: true
  validates :sso_url, presence: true, url: { protocols: %w(https) }
  validates :certificate_fingerprint, presence: true, certificate_fingerprint: true

  after_initialize :set_defaults, if: :new_record?

  delegate :assertion_consumer_service_url, :issuer, :name_identifier_format, to: :defaults

  def certificate_fingerprint=(value)
    super(strip_left_to_right_chars(value))
  end

  def settings
    defaults.to_h.merge(
      idp_cert_fingerprint: certificate_fingerprint,
      idp_sso_target_url: sso_url
    )
  end

  def defaults
    @defaults ||= DefaultOptions.new(group.full_path)
  end

  class DefaultOptions
    include Gitlab::Routing

    NAME_IDENTIFIER_FORMAT = 'urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified'.freeze

    def initialize(group_path)
      @group_path = group_path
    end

    def name_identifier_format
      NAME_IDENTIFIER_FORMAT
    end

    def issuer
      group_canonical_url(@group_path)
    end

    def assertion_consumer_service_url
      callback_group_saml_providers_url(@group_path)
    end

    def to_h
      {
        assertion_consumer_service_url: assertion_consumer_service_url,
        issuer: issuer,
        name_identifier_format: name_identifier_format,
        idp_sso_target_url_runtime_params: { redirect_to: :RelayState }
      }
    end
  end

  private

  def set_defaults
    self.enabled = true
  end

  def strip_left_to_right_chars(input)
    input&.gsub(/[\u200E]/, '')
  end
end
