# frozen_string_literal: true

module EE
  module Users
    module BuildService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(skip_authorization: false)
        user = super

        build_smartcard_identity(user, params) if ::Gitlab::Auth::Smartcard.enabled?

        user
      end

      private

      override :signup_params
      def signup_params
        super + email_opted_in_params
      end

      def email_opted_in_params
        [
          :email_opted_in,
          :email_opted_in_ip,
          :email_opted_in_source_id,
          :email_opted_in_at
        ]
      end

      def build_smartcard_identity(user, params)
        smartcard_identity_attrs = params.slice(:certificate_subject, :certificate_issuer)

        if smartcard_identity_attrs.any?
          user.smartcard_identities.build(subject: params[:certificate_subject],
                                          issuer: params[:certificate_issuer])
        end
      end
    end
  end
end
