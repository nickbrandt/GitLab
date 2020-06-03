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

      ::Feature.enabled?(EXPERIMENT_GROWTH_ONBOARDING_FEATURE_NAME, current_user, default_enabled: true)
    end
  end
end
