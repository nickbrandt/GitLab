# frozen_string_literal: true

class TrialsController < RegistrationsController
  private

  def after_sign_up_path_for(user)
    root_path
  end

  def sign_up_params
    extra_params = params.require(:user).permit(:skip_confirmation)

    super.merge(extra_params)
  end
end
