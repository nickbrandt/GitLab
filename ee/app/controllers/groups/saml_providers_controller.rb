# frozen_string_literal: true
require_relative '../concerns/saml_authorization.rb' # frozen_string_literal: true

class Groups::SamlProvidersController < Groups::ApplicationController
  include SamlAuthorization
  before_action :require_top_level_group
  before_action :authorize_manage_saml!
  before_action :check_group_saml_available!
  before_action :check_group_saml_configured

  # rubocop: disable CodeReuse/ActiveRecord
  def show
    @saml_provider = @group.saml_provider || @group.build_saml_provider

    @scim_token_exists = ScimOauthAccessToken.exists?(group: @group)
    @scim_token_url = group_scim_oauth_url(@group)
  end
  # rubocop: enable CodeReuse/ActiveRecord

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
