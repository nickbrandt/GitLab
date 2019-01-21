# frozen_string_literal: true

module Gitlab
  module Auth
    module Smartcard
      class Certificate < Gitlab::Auth::Smartcard::Base
        def auth_method
          'smartcard'
        end

        private

        def find_user
          User.find_by_smartcard_identity(subject, issuer)
        end

        def create_user
          user = User.find_by_email(email)
          if user
            create_smartcard_identity_for(user)
            return user
          end

          user_params = {
            name:                       common_name,
            username:                   username,
            email:                      email,
            password:                   password,
            password_confirmation:      password,
            password_automatically_set: true,
            certificate_subject:        subject,
            certificate_issuer:         issuer,
            skip_confirmation:          true
          }

          Users::CreateService.new(nil, user_params).execute(skip_authorization: true)
        end

        def create_smartcard_identity_for(user)
          SmartcardIdentity.create(user: user, subject: subject, issuer: issuer)
        end

        def issuer
          @certificate.issuer.to_s
        end

        def subject
          @certificate.subject.to_s
        end

        def common_name
          subject.split('/').find { |part| part =~ /CN=/ }&.remove('CN=')&.strip
        end

        def email
          subject.split('/').find { |part| part =~ /emailAddress=/ }&.remove('emailAddress=')&.strip
        end

        def username
          ::Namespace.clean_path(common_name)
        end

        def password
          @password ||= Devise.friendly_token(8)
        end
      end
    end
  end
end
