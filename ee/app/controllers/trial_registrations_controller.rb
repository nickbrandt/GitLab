# frozen_string_literal: true

class TrialRegistrationsController < RegistrationsController
  private

  def sign_up_params
    params.require(:user).permit(:first_name, :last_name, :username, :email, :password, :skip_confirmation)
  end

  def resource
    @resource ||= Users::BuildService.new(current_user, sign_up_params).execute(skip_authorization: true)
  end
end
