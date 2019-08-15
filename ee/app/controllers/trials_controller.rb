class TrialsController < RegistrationsController

  private

  def sign_up_params
    extra_params = params.require(:user).permit(:skip_confirmation)

    super.merge(extra_params)
  end
end
