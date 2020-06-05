# frozen_string_literal: true

module Registrations
  class ExperienceLevelsController < DeviseController
    # This will need to be changed to simply 'devise' as part of
    # https://gitlab.com/gitlab-org/growth/engineering/issues/64
    layout 'devise_experimental_separate_sign_up_flow'

    before_action :authenticate_user!
    before_action :check_experiment_enabled

    def update
      current_user.experience_level = params[:experience_level]

      if current_user.save
        set_flash_message! :notice, :signed_up
        redirect_to group_path(params[:namespace_path] || current_user)
      else
        render :show
      end
    end

    private

    def check_experiment_enabled
      access_denied! unless experiment_enabled?(:onboarding_issues)
    end

    # Override the default translation scope of "devise.#{controller_name}" to
    # reuse existing translations from the RegistrationsController. Also, this
    # way we're much more likely to catch problems early if that controller is
    # ever renamed.
    def translation_scope
      "devise.#{RegistrationsController.controller_name}"
    end
  end
end
