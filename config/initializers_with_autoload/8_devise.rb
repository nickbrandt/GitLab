Devise.setup do |config|
  if Gitlab::Auth::LDAP::Config.enabled?
    Gitlab::Auth::LDAP::Config.providers.each do |provider|
      ldap_config = Gitlab::Auth::LDAP::Config.new(provider)
      config.omniauth(provider, ldap_config.omniauth_options)
    end
  end

  if Gitlab::Auth.omniauth_enabled?
    Gitlab::OmniauthInitializer.new(config).execute(Gitlab.config.omniauth.providers)
  end
end
