# frozen_string_literal: true

module EE
  module GroupMember
    extend ActiveSupport::Concern

    prepended do
      extend ::Gitlab::Utils::Override

      validate :sso_enforcement, if: :group
      validate :group_domain_limitations, if: :group_has_domain_limitations?

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

    def group_has_domain_limitations?
      group.feature_available?(:group_allowed_email_domains) && group.root_ancestor_allowed_email_domain.present?
    end

    def group_domain_limitations
      if user
        validate_users_email
      else
        validate_invitation_email
      end
    end

    def validate_users_email
      return if group.root_ancestor_allowed_email_domain.email_matches_domain?(user.email)

      errors.add(:user, _("email '%{user_email}' does not match the allowed domain of '%{email_domain}'" % { user_email: user.email, email_domain: group.root_ancestor_allowed_email_domain.domain }))
    end

    def validate_invitation_email
      return if group.root_ancestor_allowed_email_domain.email_matches_domain?(invite_email)

      errors.add(:invite_email, _("'%{email}' is not in the right domain") % { email: invite_email })
    end
  end
end
