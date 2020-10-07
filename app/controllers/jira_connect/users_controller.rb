# frozen_string_literal: true

class JiraConnect::UsersController < ApplicationController
  before_action :clear_flash, only: :show

  layout 'devise_experimental_onboarding_issues'

  def show
  end

  private

  def clear_flash
    flash[:alert] = nil
  end
end
