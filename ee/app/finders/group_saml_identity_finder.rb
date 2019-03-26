# frozen_string_literal: true

class GroupSamlIdentityFinder
  attr_reader :user

  # rubocop: disable CodeReuse/ActiveRecord
  def self.find_by_group_and_uid(group:, uid:)
    return unless group.saml_provider

    group.saml_provider.identities.find_by(extern_uid: uid)
  end
  # rubocop: enable CodeReuse/ActiveRecord

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
