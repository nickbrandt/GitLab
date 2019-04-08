# frozen_string_literal: true

module EE
  module GroupMember
    extend ActiveSupport::Concern

    prepended do
      extend ::Gitlab::Utils::Override

      validate :sso_enforcement, if: :group

      scope :with_ldap_dn, -> { joins(user: :identities).where("identities.provider LIKE ?", 'ldap%') }
      scope :with_identity_provider, ->(provider) do
        joins(user: :identities).where(identities: { provider: provider })
      end

      scope :non_owners, -> { where("members.access_level < ?", ::Gitlab::Access::OWNER) }
    end

    class_methods do
      def member_of_group?(group, user)
        exists?(group: group, user: user)
      end
    end
  end
end
