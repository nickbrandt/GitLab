# frozen_string_literal: true

class TrialRegistrationsController < RegistrationsController

  private

  def sign_up_params
    params.require(:user).permit(:first_name, :last_name, :username, :email, :password, :skip_confirmation)
  end
end
