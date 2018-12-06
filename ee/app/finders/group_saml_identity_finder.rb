# frozen_string_literal: true

class GroupSamlIdentityFinder
  attr_reader :user

  def initialize(user:)
    @user = user
  end

  def find_linked(group:)
    return unless user

    group&.saml_provider&.identities&.find_by(user: user)
  end

  def all
    user.group_saml_identities.preload_saml_group
  end
end
