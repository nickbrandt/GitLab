# frozen_string_literal: true

module EE
  module OnboardingExperimentHelper
    extend ::Gitlab::Utils::Override

    EXPERIMENT_GROWTH_ONBOARDING_FEATURE_NAME = :experiment_growth_onboarding

    override :allow_access_to_onboarding?
    def allow_access_to_onboarding?
      super && experiment_enabled_for_user?
    end

    private

    def experiment_enabled_for_user?
      return true unless current_user
      # If EXPERIMENT_GROWTH_ONBOARDING_FEATURE_NAME is not set, we should return
      # true which means available for all
      return true unless onboarding_sign_up_experiment_set?

      ::Feature.enabled?(EXPERIMENT_GROWTH_ONBOARDING_FEATURE_NAME, current_user)
    end

    def onboarding_sign_up_experiment_set?
      ::Feature.persisted?(onboarding_sign_up_experiment_feature)
    end

    def onboarding_sign_up_experiment_feature
      ::Feature.get(EXPERIMENT_GROWTH_ONBOARDING_FEATURE_NAME)
    end
  end
end
