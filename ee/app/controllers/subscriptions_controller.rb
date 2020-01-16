# frozen_string_literal: true

class SubscriptionsController < ApplicationController
  layout 'checkout'
  skip_before_action :authenticate_user!, only: :new

  def new
    if experiment_enabled?(:paid_signup_flow)
      return if current_user

      store_location_for :user, request.fullpath
      redirect_to new_user_registration_path
    else
      redirect_to customer_portal_new_subscription_url
    end
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

  def customer_portal_new_subscription_url
    "#{EE::SUBSCRIPTIONS_URL}/subscriptions/new?plan_id=#{params[:plan_id]}&transaction=create_subscription"
  end
end
