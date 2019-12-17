# frozen_string_literal: true

class SubscriptionsController < ApplicationController
  layout 'checkout'

  def new
    return redirect_to dashboard_projects_path unless Feature.enabled?(:paid_signup_flow)
  end

  def payment_form
    response = client.payment_form_params(params[:id])
    render json: response[:data]
  end

  def payment_method
    response = client.payment_method(params[:id])
    render json: response[:data]
  end

  private

  def client
    Gitlab::SubscriptionPortal::Client
  end
end
