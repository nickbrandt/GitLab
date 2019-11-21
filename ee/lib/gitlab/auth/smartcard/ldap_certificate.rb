# frozen_string_literal: true

module Gitlab
  module Auth
    module Smartcard
      class LDAPCertificate < Gitlab::Auth::Smartcard::Base
        def initialize(provider, certificate)
          super(certificate)

          @provider = provider
        end

        def auth_method
          'smartcard_ldap'
        end

        private

        def find_user
          identity = Identity.find_by_extern_uid(@provider, ldap_user.dn)
          identity&.user
        end

        def create_identity_for_existing_user
          # TODO: create new identity for existing users as part of https://gitlab.com/gitlab-org/gitlab/issues/36808
        end

        def create_user
          user_params = {
            name:                       ldap_user.name,
            username:                   username,
            email:                      ldap_user.email.first,
            extern_uid:                 ldap_user.dn,
            provider:                   @provider,
            password:                   password,
            password_confirmation:      password,
            password_automatically_set: true,
            skip_confirmation:          true
          }

          Users::CreateService.new(nil, user_params).execute(skip_authorization: true)
        end

        def adapter
          @adapter ||= Gitlab::Auth::LDAP::Adapter.new(@provider)
        end

        def ldap_user
          @ldap_user ||= ::Gitlab::Auth::LDAP::Person.find_by_certificate_issuer_and_serial(
            @certificate.issuer.to_s(OpenSSL::X509::Name::RFC2253),
            @certificate.serial.to_s,
            adapter)
        end

        def username
          ::Namespace.clean_path(ldap_user.username)
        end

        def password
          @password ||= Devise.friendly_token(8)
        end
      end
    end
  end
end
