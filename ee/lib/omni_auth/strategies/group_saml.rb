# frozen_string_literal: true

module OmniAuth
  module Strategies
    class GroupSaml < SAML
      extend ::Gitlab::Utils::Override

      option :name, 'group_saml'
      option :callback_path, ->(env) { callback?(env) }

      override :setup_phase
      def setup_phase
        if metadata_phase?
          require_discovery_token
        else
          require_saml_provider
        end

        # Set devise scope for custom callback URL
        env["devise.mapping"] = Devise.mappings[:user]

        settings = Gitlab::Auth::GroupSaml::DynamicSettings.new(group_lookup.group).to_h
        env['omniauth.strategy'].options.merge!(settings)

        super
      end

      # Prevent access to SLO endpoints. These make less sense at
      # group level and would need additional work to securely support
      override :other_phase
      def other_phase
        if metadata_phase?
          super
        else
          call_app!
        end
      end

      def self.invalid_group!(path)
        raise ActionController::RoutingError, path
      end

      def self.callback?(env)
        env['PATH_INFO'] =~ Gitlab::PathRegex.saml_callback_regex
      end

      private

      def metadata_phase?
        on_subpath?(:metadata) && metadata_enabled?
      end

      def metadata_enabled?
        Feature.enabled?(:group_saml_metadata_available)
      end

      def group_lookup
        @group_lookup ||= Gitlab::Auth::GroupSaml::GroupLookup.new(env)
      end

      def require_saml_provider
        unless group_lookup.group_saml_enabled?
          self.class.invalid_group!(group_lookup.path)
        end
      end

      def require_discovery_token
        unless group_lookup.token_discoverable?
          self.class.invalid_group!(group_lookup.path)
        end
      end
    end
  end
end
