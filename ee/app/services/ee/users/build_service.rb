# frozen_string_literal: true

module EE
  module Users
    module BuildService
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize

      attr_reader :group_id_for_saml

      override :initialize
      def initialize(current_user, params = {})
        super
        @group_id_for_saml = params.delete(:group_id_for_saml)
      end

      override :execute
      def execute(skip_authorization: false)
        user = super

        build_smartcard_identity(user, params) if ::Gitlab::Auth::Smartcard.enabled?

        user
      end

      private

      override :signup_params
      def signup_params
        super + email_opted_in_params + name_params
      end

      def email_opted_in_params
        [
          :email_opted_in,
          :email_opted_in_ip,
          :email_opted_in_source_id,
          :email_opted_in_at
        ]
      end

      def name_params
        [
          :first_name,
          :last_name
        ]
      end

      override :identity_attributes
      def identity_attributes
        super.push(:saml_provider_id)
      end

      override :identity_params
      def identity_params
        if group_id_for_saml.present?
          super.merge(saml_provider_id: saml_provider_id)
        else
          super
        end
      end

      def saml_provider_id
        strong_memoize(:saml_provider_id) do
          group = GroupFinder.new(current_user).execute(id: group_id_for_saml)
          group&.saml_provider&.id
        end
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
