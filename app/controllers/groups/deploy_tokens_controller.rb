# frozen_string_literal: true

class Groups::DeployTokensController < Groups::ApplicationController
  before_action :authorize_admin_project!

  def revoke
    @token = @group.deploy_tokens.find(params[:id])
    @token.revoke!

    redirect_to group_settings_ci_cd_path(project, anchor: 'js-deploy-tokens')
  end
end
