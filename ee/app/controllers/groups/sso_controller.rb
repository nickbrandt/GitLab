# frozen_string_literal: true

class Groups::SsoController < Groups::ApplicationController
  skip_before_action :group
  before_action :unauthenticated_group
  before_action :check_group_saml_configured
  before_action :check_group_saml_available!
  before_action :require_configured_provider
  before_action :authenticate_user!, only: [:unlink]
  before_action :check_user_can_sign_in_with_provider, only: [:saml]
  before_action :redirect_if_group_moved

  layout 'devise'

  def saml
    @group_path = params[:group_id]
    @group_name = @unauthenticated_group.full_name
    @group_saml_identity = linked_identity
    @idp_url = @unauthenticated_group.saml_provider.sso_url
  end

  def unlink
    return route_not_found unless linked_identity

    GroupSaml::Identity::DestroyService.new(linked_identity).execute

    redirect_to profile_account_path
  end

  private

  def linked_identity
    @linked_identity ||= GroupSamlIdentityFinder.new(user: current_user).find_linked(group: @unauthenticated_group)
  end

  def check_group_saml_available!
    route_not_found unless @unauthenticated_group.feature_available?(:group_saml)
  end

  def check_group_saml_configured
    route_not_found unless Gitlab::Auth::GroupSaml::Config.enabled?
  end

  def unauthenticated_group
    @unauthenticated_group = Group.find_by_full_path(params[:group_id], follow_redirects: true)

    route_not_found unless @unauthenticated_group
  end

  def require_configured_provider
    return if @unauthenticated_group.saml_provider

    if can?(current_user, :admin_group_saml, @unauthenticated_group)
      flash[:notice] = 'SAML sign on has not been configured for this group'

      redirect_to [@unauthenticated_group, :saml_providers]
    else
      route_not_found
    end
  end

  def check_user_can_sign_in_with_provider
    actor = saml_discovery_token_actor || current_user
    route_not_found unless can?(actor, :sign_in_with_saml_provider, @unauthenticated_group.saml_provider)
  end

  def saml_discovery_token_actor
    Gitlab::Auth::GroupSaml::TokenActor.new(params[:token]) if params[:token]
  end

  def redirect_if_group_moved
    ensure_canonical_path(@unauthenticated_group, params[:group_id])
  end
end
