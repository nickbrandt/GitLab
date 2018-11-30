# frozen_string_literal: true

module Gitlab
  module Auth
    module Smartcard
      class Certificate
        InvalidCAFilePath = Class.new(StandardError)
        InvalidCertificate = Class.new(StandardError)

        delegate :allow_signup?,
                 to: :'Gitlab::CurrentSettings.current_application_settings'

        def self.store
          @store ||= OpenSSL::X509::Store.new.tap do |store|
            store.add_cert(
              OpenSSL::X509::Certificate.new(
                File.read(Gitlab.config.smartcard.ca_file)))
          end
        rescue Errno::ENOENT => ex
          Gitlab::AppLogger.error('Failed to open Gitlab.config.smartcard.ca_file')
          Gitlab::AppLogger.error(ex)
          raise InvalidCAFilePath
        rescue OpenSSL::X509::CertificateError => ex
          Gitlab::AppLogger.error('Gitlab.config.smartcard.ca_file is not a valid certificate')
          Gitlab::AppLogger.error(ex)
          raise InvalidCertificate
        end

        def initialize(certificate)
          @certificate = OpenSSL::X509::Certificate.new(certificate)
          @subject = @certificate.subject.to_s
          @issuer = @certificate.issuer.to_s
        rescue OpenSSL::X509::CertificateError
          # no-op
        end

        def find_or_create_user
          return unless valid?

          user = find_user
          user ||= create_user if allow_signup?
          user
        end

        private

        def valid?
          self.class.store.verify(@certificate) if @certificate
        end

        def find_user
          User.find_by_smartcard_identity(@subject, @issuer)
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
            certificate_subject:        @subject,
            certificate_issuer:         @issuer,
            skip_confirmation:          true
          }

          Users::CreateService.new(nil, user_params).execute(skip_authorization: true)
        end

        def create_smartcard_identity_for(user)
          SmartcardIdentity.create(user: user, subject: @subject, issuer: @issuer)
        end

        def common_name
          @subject.split('/').find { |part| part =~ /CN=/ }&.remove('CN=')&.strip
        end

        def email
          @subject.split('/').find { |part| part =~ /emailAddress=/ }&.remove('emailAddress=')&.strip
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
