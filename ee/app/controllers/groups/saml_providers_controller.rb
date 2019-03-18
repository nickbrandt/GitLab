# frozen_string_literal: true
require_relative '../concerns/saml_authorization.rb'

class Groups::SamlProvidersController < Groups::ApplicationController
  include SamlAuthorization
  before_action :require_top_level_group
  before_action :authorize_manage_saml!
  before_action :check_group_saml_available!
  before_action :check_group_saml_configured

  def show
    @saml_provider = @group.saml_provider || @group.build_saml_provider

    scim_token = ScimOauthAccessToken.find_by_group_id(@group.id)

    @scim_token_url = scim_token.as_entity_json[:scim_api_url] if scim_token
  end

  def create
    @saml_provider = @group.build_saml_provider(saml_provider_params)

    @saml_provider.save

    render :show
  end

  def update
    @saml_provider = @group.saml_provider

    GroupSaml::SamlProvider::UpdateService.new(current_user, @saml_provider, params: saml_provider_params).execute

    render :show
  end

  private

  def saml_provider_params
    allowed_params = %i[sso_url certificate_fingerprint enabled]

    allowed_params += [:enforced_sso] if Feature.enabled?(:enforced_sso, group)
    allowed_params += [:enforced_group_managed_accounts] if Feature.enabled?(:group_managed_accounts, group)

    params.require(:saml_provider).permit(allowed_params)
  end
end
