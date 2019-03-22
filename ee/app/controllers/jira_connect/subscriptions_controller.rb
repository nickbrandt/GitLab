# frozen_string_literal: true

class JiraConnect::SubscriptionsController < JiraConnect::ApplicationController
  layout 'jira_connect'

  before_action :allow_rendering_in_iframe, only: :index
  before_action :verify_qsh_claim!, only: :index
  before_action :authenticate_user!, only: :create

  def index
    @subscriptions = current_jira_installation.subscriptions.preload_namespace_route
  end

  def create
    result = create_service.execute

    if result[:status] == :success
      render json: { success: true }
    else
      render json: { error: result[:message] }, status: result[:http_status]
    end
  end

  def destroy
    subscription = current_jira_installation.subscriptions.find(params[:id])

    if subscription.destroy
      render json: { success: true }
    else
      render json: { error: subscription.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  private

  def create_service
    JiraConnectSubscriptions::CreateService.new(current_jira_installation, current_user, namespace_path: params['namespace_path'])
  end

  def allow_rendering_in_iframe
    response.headers.delete('X-Frame-Options')
  end
end
