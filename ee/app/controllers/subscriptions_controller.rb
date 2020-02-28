# frozen_string_literal: true

class SubscriptionsController < ApplicationController
  layout 'checkout'
  skip_before_action :authenticate_user!, only: :new

  content_security_policy do |p|
    next if p.directives.blank?
    next unless Feature.enabled?(:paid_signup_flow)

    default_script_src = p.directives['script-src'] || p.directives['default-src']
    script_src_values = Array.wrap(default_script_src) | ["'self'", "'unsafe-eval'", 'https://*.zuora.com']

    default_frame_src = p.directives['frame-src'] || p.directives['default-src']
    frame_src_values = Array.wrap(default_frame_src) | ["'self'", 'https://*.zuora.com']

    default_child_src = p.directives['child-src'] || p.directives['default-src']
    child_src_values = Array.wrap(default_child_src) | ["'self'", 'https://*.zuora.com']

    p.script_src(*script_src_values)
    p.frame_src(*frame_src_values)
    p.child_src(*child_src_values)
  end

  def new
    if experiment_enabled?(:paid_signup_flow)
      if current_user
        track_paid_signup_flow_event('start')
      else
        store_location_for :user, request.fullpath
        redirect_to new_user_registration_path
      end
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

  def create
    current_user.update(setup_for_company: true) if params[:setup_for_company]

    if params[:selected_group]
      group = current_user.managed_free_namespaces.find(params[:selected_group])
    else
      group_name = params[:setup_for_company] ? customer_params[:company] : "#{current_user.name}'s Group"
      path = Namespace.clean_path(group_name)
      group = Groups::CreateService.new(current_user, name: group_name, path: path).execute
      return render json: group.errors.to_json unless group.persisted?
    end

    response = Subscriptions::CreateService.new(
      current_user,
      group: group,
      customer_params: customer_params,
      subscription_params: subscription_params
    ).execute

    if response[:success]
      redirect_location = if params[:selected_group]
                            group_path(group)
                          else
                            plan_id, quantity = subscription_params.values_at(:plan_id, :quantity)
                            edit_subscriptions_group_path(group.path, plan_id: plan_id, quantity: quantity, new_user: params[:new_user])
                          end

      response[:data] = { location: redirect_location }

      track_paid_signup_flow_event('end', label: plan_id, value: quantity)
    end

    render json: response[:data]
  end

  private

  def track_paid_signup_flow_event(action, label: nil, value: nil)
    ::Gitlab::Tracking.event(
      'Growth::Acquisition::Experiment::PaidSignUpFlow',
      action,
      label: label,
      value: value
    )
  end

  def customer_params
    params.require(:customer).permit(:country, :address_1, :address_2, :city, :state, :zip_code, :company)
  end

  def subscription_params
    params.require(:subscription).permit(:plan_id, :payment_method_id, :quantity)
  end

  def client
    Gitlab::SubscriptionPortal::Client
  end

  def customer_portal_new_subscription_url
    "#{EE::SUBSCRIPTIONS_URL}/subscriptions/new?plan_id=#{params[:plan_id]}&transaction=create_subscription"
  end
end
