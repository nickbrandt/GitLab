# frozen_string_literal: true

class SamlProviderPolicy < BasePolicy
  delegate { @subject.group }

  def actor
    @user
  end

  condition(:public_group, scope: :subject) { @subject.group.public? }

  condition(:signed_in, scope: :user) { actor.is_a?(::User) }

  condition(:token_grants_private_access) do
    actor.is_a?(Gitlab::Auth::GroupSaml::TokenActor) && actor.valid_for?(@subject.group)
  end

  condition(:can_discover_group?) do
    public_group? || token_grants_private_access? || signed_in?
  end

  rule { can_discover_group? }.enable :sign_in_with_saml_provider
end
