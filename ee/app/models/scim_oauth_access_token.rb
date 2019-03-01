# frozen_string_literal: true

class ScimOauthAccessToken < ActiveRecord::Base
  include TokenAuthenticatable

  belongs_to :group

  add_authentication_token_field :token

  validates :group, presence: true
  before_save :ensure_token
end
