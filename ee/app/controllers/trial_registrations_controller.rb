# frozen_string_literal: true

class TrialRegistrationsController < RegistrationsController
  before_action :check_if_gl_com
  before_action :check_if_improved_trials_enabled

  def create
    super do |new_user|
      new_user.system_hook_service.execute_hooks_for(new_user, :create)
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:first_name, :last_name, :username, :email, :password, :skip_confirmation, :email_opted_in)
  end

  def resource
    @resource ||= Users::BuildService.new(current_user, sign_up_params).execute(skip_authorization: true)
  end

  def check_if_gl_com
    render_404 unless Gitlab.com?
  end

  def check_if_improved_trials_enabled
    render_404 unless Feature.enabled?(:improved_trial_signup)
  end
end
