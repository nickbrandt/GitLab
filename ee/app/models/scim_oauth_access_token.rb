# frozen_string_literal: true

class ScimOauthAccessToken < ApplicationRecord
  include TokenAuthenticatable

  belongs_to :group

  add_authentication_token_field :token, encrypted: :required

  validates :group, presence: true
  before_save :ensure_token

  def as_entity_json
    ScimOauthAccessTokenEntity.new(self).as_json
  end
end
