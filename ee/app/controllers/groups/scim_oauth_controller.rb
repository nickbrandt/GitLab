# frozen_string_literal: true

class Groups::ScimOauthController < Groups::ApplicationController
  # before_action :require_top_level_group
  # before_action :authorize_manage_saml!
  # before_action :check_group_saml_available!
  # before_action :check_group_saml_configured
  skip_before_filter :verify_authenticity_token


  def show
    scim_token = ScimOauthAccessToken.find_by_group_id(@group.id)

    respond_to do |format|
      format.json do
        if scim_token
          render json: ScimOauthAccessTokenEntity.new(scim_token).as_json
        else
          render json: {}
        end
      end
    end
  end

  def create
    scim_token = ScimOauthAccessToken.safe_find_or_create_by(group: @group)

    respond_to do |format|
      format.json do
        if scim_token&.valid?
          render json: ScimOauthAccessTokenEntity.new(scim_token).as_json
        else
          render json: { errors: scim_token&.errors&.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
