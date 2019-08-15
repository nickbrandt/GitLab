# frozen_string_literal: true

class TrialsController < RegistrationsController
  before_action :set_redirect_url, only: [:new]

  private

  def set_redirect_url
    store_location_for(:user, root_url)
  end

  def sign_up_params
    extra_params = params.require(:user).permit(:skip_confirmation)

    super.merge(extra_params)
  end
end
