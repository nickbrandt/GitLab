# frozen_string_literal: true

class Groups::ScimOauthController < Groups::ApplicationController
  before_action :require_top_level_group
  before_action :authorize_manage_saml!
  before_action :check_group_saml_available!
  before_action :check_group_saml_configured

  def show
    @saml_provider = @group.saml_provider || @group.build_saml_provider
  end

  def create
    @saml_provider = @group.build_saml_provider(saml_provider_params)

    @saml_provider.save

    render :show
  end
end
