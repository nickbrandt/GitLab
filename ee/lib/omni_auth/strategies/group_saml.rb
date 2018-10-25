module OmniAuth
  module Strategies
    class GroupSaml < SAML
      option :name, 'group_saml'
      option :callback_path, ->(env) { callback?(env) }

      def setup_phase
        require_saml_provider

        # Set devise scope for custom callback URL
        env["devise.mapping"] = Devise.mappings[:user]

        settings = Gitlab::Auth::GroupSaml::DynamicSettings.new(group_lookup.group).to_h
        env['omniauth.strategy'].options.merge!(settings)

        super
      end

      # Prevent access to SLO and metadata endpoints
      # These will need addtional work to securely support
      def other_phase
        call_app!
      end

      def self.invalid_group!(path)
        raise ActionController::RoutingError, path
      end

      def self.callback?(env)
        env['PATH_INFO'] =~ Gitlab::PathRegex.saml_callback_regex
      end

      private

      def group_lookup
        @group_lookup ||= Gitlab::Auth::GroupSaml::GroupLookup.new(env)
      end

      def require_saml_provider
        unless group_lookup.group_saml_enabled?
          self.class.invalid_group!(group_lookup.path)
        end
      end
    end
  end
end
