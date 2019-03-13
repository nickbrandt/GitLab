# frozen_string_literal: true

class JiraConnect::EventsController < JiraConnect::ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :verify_atlassian_jwt!, only: :installed

  def installed
    if JiraConnectInstallation.create(install_params)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def uninstalled
    if current_jira_installation.destroy
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def install_params
    params.permit(:clientKey, :sharedSecret, :baseUrl).transform_keys(&:underscore)
  end
end
