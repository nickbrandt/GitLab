# frozen_string_literal: true

class TrialsController < ApplicationController
  before_action :check_if_gl_com
  before_action :check_if_improved_trials_enabled
  before_action :authenticate_user!

  def new
  end

  def select
  end

  def create_lead
    result = GitlabSubscriptions::CreateLeadService.new.execute({ trial_user: company_params })

    if result[:success]
      redirect_to select_namespace_trials_url
    else
      render :new
    end
  end

  private

  def authenticate_user!
    return if current_user

    redirect_to new_trial_registration_path, alert: I18n.t('devise.failure.unauthenticated')
  end

  def company_params
    params.permit(:company_name, :company_size, :phone_number, :number_of_users, :country)
          .merge(extra_params)
  end

  def extra_params
    attrs = current_user.slice(:first_name, :last_name)
    attrs[:work_email] = current_user.email
    attrs[:uid] = current_user.id
    attrs[:skip_email_confirmation] = true
    attrs[:gitlab_com_trial] = true
    attrs[:provider] = 'gitlab'

    attrs
  end

  def check_if_improved_trials_enabled
    render_404 unless Feature.enabled?(:improved_trial_signup)
  end
end
