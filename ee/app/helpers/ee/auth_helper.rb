# frozen_string_literal: true

module EE
  module AuthHelper
    extend ::Gitlab::Utils::Override

    GROUP_LEVEL_PROVIDERS = %i(group_saml).freeze

    delegate :slack_app_id, to: :'Gitlab::CurrentSettings.current_application_settings'

    override :display_providers_on_profile?
    def display_providers_on_profile?
      super || group_saml_enabled?
    end

    override :button_based_providers
    def button_based_providers
      super - GROUP_LEVEL_PROVIDERS
    end

    override :providers_for_base_controller
    def providers_for_base_controller
      super - GROUP_LEVEL_PROVIDERS
    end

    override :form_based_provider_priority
    def form_based_provider_priority
      super << 'smartcard'
    end

    override :form_based_provider?
    def form_based_provider?(name)
      super || name.to_s == 'kerberos'
    end

    override :form_based_providers
    def form_based_providers
      providers = super

      providers << :smartcard if smartcard_enabled?

      providers
    end

    def kerberos_enabled?
      auth_providers.include?(:kerberos)
    end

    def smartcard_enabled?
      ::Gitlab::Auth::Smartcard.enabled?
    end

    def group_saml_enabled?
      auth_providers.include?(:group_saml)
    end

    def slack_redirect_uri(project)
      slack_auth_project_settings_slack_url(project)
    end
  end
end
