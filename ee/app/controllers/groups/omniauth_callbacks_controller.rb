# frozen_string_literal: true

class Groups::OmniauthCallbacksController < OmniauthCallbacksController
  extend ::Gitlab::Utils::Override

  skip_before_action :verify_authenticity_token, only: [:failure, :group_saml]

  def group_saml
    @unauthenticated_group = Group.find_by_full_path(params[:group_id])
    @saml_provider = @unauthenticated_group.saml_provider

    identity_linker = Gitlab::Auth::GroupSaml::IdentityLinker.new(current_user, oauth, @saml_provider)

    omniauth_flow(Gitlab::Auth::GroupSaml, identity_linker: identity_linker)
  end

  private

  override :redirect_identity_linked
  def redirect_identity_linked
    flash[:notice] = "SAML for #{@unauthenticated_group.name} was added to your connected accounts"

    redirect_to after_sign_in_path_for(current_user)
  end

  override :redirect_identity_exists
  def redirect_identity_exists
    flash[:notice] = "Already signed in with SAML for #{@unauthenticated_group.name}"

    redirect_to after_sign_in_path_for(current_user)
  end

  override :redirect_identity_link_failed
  def redirect_identity_link_failed(error_message)
    flash[:notice] = "SAML authentication failed: #{error_message}"

    redirect_to after_sign_in_path_for(current_user)
  end

  override :sign_in_and_redirect
  def sign_in_and_redirect(user, *args)
    flash[:notice] = "Signed in with SAML for #{@unauthenticated_group.name}"

    super
  end

  override :after_sign_in_path_for
  def after_sign_in_path_for(resource)
    saml_redirect_path || super
  end

  override :build_auth_user
  def build_auth_user(auth_user_class)
    Gitlab::Auth::GroupSaml::User.new(oauth, @saml_provider)
  end

  override :sign_in_user_flow
  def sign_in_user_flow(auth_user_class)
    # User has successfully authenticated with the SAML provider for the group
    # but is not signed in to the GitLab instance.

    if sign_in_to_gitlab_enabled?
      super
    else
      flash[:notice] = "You must be signed in to use SAML with this group"

      redirect_to new_user_session_path
    end
  end

  def sign_in_to_gitlab_enabled?
    ::Feature.enabled?(:group_saml_allows_sign_in_to_gitlab, @unauthenticated_group)
  end

  override :fail_login
  def fail_login(user)
    if user
      super
    else
      redirect_to_login_or_register
    end
  end

  def redirect_to_login_or_register
    notice = "Login to a GitLab account to link with your SAML identity"

    after_gitlab_sign_in = sso_group_saml_providers_path(@unauthenticated_group)

    store_location_for(:redirect, after_gitlab_sign_in)
    redirect_to new_user_session_path, notice: notice
  end

  def saml_redirect_path
    params['RelayState'].presence if current_user
  end

  override :find_message
  def find_message(kind, options = {})
    _('Unable to sign you in to the group with SAML due to "%{reason}"') % options
  end

  override :after_omniauth_failure_path_for
  def after_omniauth_failure_path_for(scope)
    group_saml_failure_path(scope)
  end

  def group_saml_failure_path(scope)
    group = Gitlab::Auth::GroupSaml::GroupLookup.new(request.env).group

    unless can?(current_user, :sign_in_with_saml_provider, group&.saml_provider)
      OmniAuth::Strategies::GroupSaml.invalid_group!(group&.path)
    end

    if can?(current_user, :admin_group_saml, group)
      group_saml_providers_path(group)
    else
      sso_group_saml_providers_path(group)
    end
  end
end
