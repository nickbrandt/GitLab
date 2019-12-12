# frozen_string_literal: true

class SubscriptionsController < ApplicationController
  layout 'checkout'

  def new
    return redirect_to dashboard_projects_path unless Feature.enabled?(:paid_signup_flow)
  end
end
