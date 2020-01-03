# frozen_string_literal: true

module EE
  module GroupMember
    extend ActiveSupport::Concern

    prepended do
      extend ::Gitlab::Utils::Override
      include UsageStatistics

      validate :sso_enforcement, if: :group
      validate :group_domain_limitations, if: :group_has_domain_limitations?

      scope :with_ldap_dn, -> { joins(user: :identities).where("identities.provider LIKE ?", 'ldap%') }
      scope :with_identity_provider, ->(provider) do
        joins(user: :identities).where(identities: { provider: provider })
      end
      scope :with_saml_identity, ->(provider) do
        joins(user: :identities).where(identities: { saml_provider_id: provider })
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
      user ? validate_users_email : validate_invitation_email
    end

    def validate_users_email
      return if group_allowed_email_domain.email_matches_domain?(user.email)

      errors.add(:user, email_no_match_email_domain(user.email))
    end

    def validate_invitation_email
      return if group_allowed_email_domain.email_matches_domain?(invite_email)

      errors.add(:invite_email, email_no_match_email_domain(invite_email))
    end

    def group_saml_identity
      return unless source.saml_provider

      if user.group_saml_identities.loaded?
        user.group_saml_identities.detect { |i| i.saml_provider_id == source.saml_provider.id }
      else
        user.group_saml_identities.find_by(saml_provider: source.saml_provider)
      end
    end

    private

    def email_no_match_email_domain(email)
      _("email '%{email}' does not match the allowed domain of '%{email_domain}'" % { email: email, email_domain: group_allowed_email_domain.domain })
    end

    def group_allowed_email_domain
      group.root_ancestor_allowed_email_domain
    end
  end
end
